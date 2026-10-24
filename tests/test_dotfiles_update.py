import os
import re
import subprocess
from pathlib import Path

import pytest
from conftest import ROOT

TEMPLATE = ROOT / "home/dot_local/bin/executable_dotfiles-update.tmpl"
FAKE_NVIM = """#!/usr/bin/env bash
printf 'nvim %s\\n' "$*" >> {calls}
case "$2" in
'+Lazy! update') printf '{{"plugin": "new"}}\\n' > {lockfile} ;;
'+Lazy! load all')
  [[ ${{NVIM_FAILS:-false}} == false ]] || printf 'E5113: Lua chunk: boom\\n' >&2
  ;;
esac
"""


def git(cwd: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(cwd), *args],
        capture_output=True,
        text=True,
        check=True,
    ).stdout


@pytest.fixture
def machine(tmp_path: Path) -> tuple[Path, Path, dict[str, str]]:
    remote = tmp_path / "remote.git"
    repo = tmp_path / "repo"
    subprocess.run(["git", "init", "--quiet", "--bare", str(remote)], check=True)
    subprocess.run(["git", "clone", "--quiet", str(remote), str(repo)], check=True)
    git(repo, "config", "user.name", "Test")
    git(repo, "config", "user.email", "test@example.com")
    (repo / "nvim").mkdir()
    (repo / "nvim/lazy-lock.json").write_text('{"plugin": "old"}\n')
    git(repo, "add", ".")
    git(repo, "commit", "--quiet", "-m", "Initial")
    git(repo, "push", "--quiet", "--set-upstream", "origin", "HEAD")

    rendered = subprocess.run(
        ["chezmoi", "--source", str(ROOT), "execute-template"],
        input=TEMPLATE.read_text(),
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    rendered = re.sub(r"^repo=.*$", f"repo={repo}", rendered, count=1, flags=re.M)
    script = tmp_path / "dotfiles-update"
    script.write_text(rendered)
    script.chmod(0o755)

    home = tmp_path / "home"
    bin_dir = tmp_path / "bin"
    shims = home / ".local/share/mise/shims"
    for directory in (bin_dir, shims, home / ".t3/runtime"):
        directory.mkdir(parents=True)
    (home / ".t3/runtime/service-state.json").write_text("{}\n")
    calls = tmp_path / "calls"
    for tool in ("mise", "chezmoi", "t3"):
        stub = bin_dir / tool
        stub.write_text(f'#!/usr/bin/env bash\nprintf "{tool} %s\\n" "$*" >> {calls}\n')
        stub.chmod(0o755)
    nvim = shims / "nvim"
    lockfile = repo / "nvim/lazy-lock.json"
    nvim.write_text(FAKE_NVIM.format(calls=calls, lockfile=lockfile))
    nvim.chmod(0o755)
    env = {
        **os.environ,
        "HOME": str(home),
        "PATH": f"{bin_dir}:/usr/bin:/bin",
        "GIT_AUTHOR_NAME": "Test",
        "GIT_AUTHOR_EMAIL": "test@example.com",
        "GIT_COMMITTER_NAME": "Test",
        "GIT_COMMITTER_EMAIL": "test@example.com",
    }
    return script, repo, env


def test_update_commits_and_pushes_a_working_plugin_update(
    machine: tuple[Path, Path, dict[str, str]],
) -> None:
    script, repo, env = machine
    result = subprocess.run([str(script)], env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    calls = (script.parent / "calls").read_text().splitlines()
    assert calls[:5] == [
        "mise self-update -y",
        "chezmoi update",
        "mise install",
        "mise up",
        "t3 update --yes",
    ]
    assert git(repo, "log", "-1", "--format=%s").strip() == "Update nvim plugins"
    assert git(repo, "show", "--name-only", "--format=", "HEAD").split() == [
        "nvim/lazy-lock.json"
    ]
    assert git(repo, "rev-list", "--count", "@{u}..HEAD").strip() == "0"


def test_update_restores_plugins_when_nvim_fails(
    machine: tuple[Path, Path, dict[str, str]],
) -> None:
    script, repo, env = machine
    result = subprocess.run(
        [str(script)], env={**env, "NVIM_FAILS": "true"}, capture_output=True, text=True
    )
    assert result.returncode == 1
    assert "E5113" in result.stderr
    assert "nothing was committed" in result.stderr
    assert (repo / "nvim/lazy-lock.json").read_text() == '{"plugin": "old"}\n'
    assert "nvim --headless +Lazy! restore +qa" in (script.parent / "calls").read_text()
    assert git(repo, "log", "-1", "--format=%s").strip() == "Initial"


def test_update_skips_the_commit_without_plugin_changes(
    machine: tuple[Path, Path, dict[str, str]],
) -> None:
    script, repo, env = machine
    nvim = Path(env["HOME"]) / ".local/share/mise/shims/nvim"
    nvim.write_text("#!/usr/bin/env bash\n")
    result = subprocess.run([str(script)], env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    assert git(repo, "log", "-1", "--format=%s").strip() == "Initial"
