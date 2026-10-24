import json
import os
import pwd
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest
from conftest import ROOT
from test_setup import Shell
from test_setup import linux as linux


@pytest.fixture
def pitchfork_env(tmp_path: Path) -> dict[str, str]:
    binary = tmp_path / "bin/pitchfork"
    binary.parent.mkdir()
    binary.write_text(
        f"#!{sys.executable}\n"
        "import json, os, sys\n"
        "with open(os.environ['CALLS'], 'a') as file:\n"
        "    file.write(json.dumps(sys.argv[1:]) + '\\n')\n"
    )
    binary.chmod(0o755)
    return {
        **os.environ,
        "PATH": f"{binary.parent}:{os.environ['PATH']}",
        "XDG_CONFIG_HOME": str(tmp_path / "config"),
        "PITCHFORK_STATE_DIR": str(tmp_path / "state"),
        "CALLS": str(tmp_path / "calls.jsonl"),
    }


def run_script(
    name: str, env: dict[str, str], *args: str
) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(ROOT / f"home/dot_local/bin/executable_{name}"), *args],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


def calls(env: dict[str, str]) -> list[list[str]]:
    path = Path(env["CALLS"])
    return (
        [json.loads(line) for line in path.read_text().splitlines()]
        if path.exists()
        else []
    )


def test_register_preserves_overrides_and_sets_checkout_specific_namespace(
    tmp_path: Path, pitchfork_env: dict[str, str]
) -> None:
    root = tmp_path / "animations"
    root.mkdir()
    local = root / "pitchfork.local.toml"
    local.write_text("[daemons.dev]\nport = 3005\n")
    for _ in range(2):
        result = run_script(
            "pitchfork-register",
            pitchfork_env,
            "portfolio-animations",
            "--dir",
            str(root),
        )
        assert result.returncode == 0, result.stderr
    assert tomllib.loads(local.read_text()) == {
        "namespace": "portfolio-animations",
        "daemons": {"dev": {"port": 3005}},
    }
    assert len(calls(pitchfork_env)) == 2


def test_register_rejects_dotted_slug_without_changes(
    tmp_path: Path, pitchfork_env: dict[str, str]
) -> None:
    result = run_script(
        "pitchfork-register",
        pitchfork_env,
        "app.worktree",
        "--dir",
        str(tmp_path),
    )
    assert result.returncode != 0
    assert "without dots" in result.stderr
    assert not (tmp_path / "pitchfork.local.toml").exists()
    assert not calls(pitchfork_env)


def test_register_rejects_conflicting_namespace_without_changes(
    tmp_path: Path, pitchfork_env: dict[str, str]
) -> None:
    config = tmp_path / "pitchfork.toml"
    config.write_text('namespace = "custom"\n[daemons.dev]\nrun = "sleep 60"\n')
    result = run_script(
        "pitchfork-register",
        pitchfork_env,
        "portfolio-animations",
        "--dir",
        str(tmp_path),
    )
    assert result.returncode != 0
    assert "declares namespace" in result.stderr
    assert not (tmp_path / "pitchfork.local.toml").exists()
    assert not calls(pitchfork_env)


@pytest.fixture
def modifier(tmp_path: Path) -> tuple[list[str], Path]:
    chezmoi = shutil.which("chezmoi")
    assert chezmoi is not None, "Install the test dependency with: mise install chezmoi"
    source = tmp_path / "source"
    template = source / "dot_config/pitchfork/modify_config.toml"
    template.parent.mkdir(parents=True)
    shutil.copyfile(ROOT / "home/dot_config/pitchfork/modify_config.toml", template)
    shutil.copyfile(ROOT / "home/.chezmoidata.toml", source / ".chezmoidata.toml")
    target = tmp_path / "home/.config/pitchfork/config.toml"
    target.parent.mkdir(parents=True)
    config = tmp_path / "chezmoi.toml"
    config.write_text("")
    command = [
        chezmoi,
        "--config",
        str(config),
        "--source",
        str(source),
        "--destination",
        str(tmp_path / "home"),
        "--persistent-state",
        str(tmp_path / "state.boltdb"),
        "--force",
        "apply",
        str(target),
    ]
    return command, target


MANAGED_SETTINGS = {
    "proxy": {
        "enable": True,
        "host": "127.0.0.1",
        "port": 9443,
        "sync_hosts": False,
        "tld": tomllib.loads((ROOT / "home/.chezmoidata.toml").read_text())["proxy"][
            "tld"
        ],
    },
    "supervisor": {"user": pwd.getpwuid(os.getuid()).pw_name},
}


@pytest.mark.parametrize(
    "config",
    [
        "",
        'namespace = "global"\n[daemons.other]\nrun = "keep"\n'
        '[slugs]\napp = {dir = "/app", daemon = "dev"}\n',
        '[settings]\nlog_level = "debug"\n[settings.proxy]\nport = 1\nhttps = false\n',
    ],
)
def test_settings_modifier_preserves_other_configuration(
    config: str, modifier: tuple[list[str], Path]
) -> None:
    command, target = modifier

    def apply(value: str) -> str:
        target.write_text(value)
        subprocess.run(command, text=True, capture_output=True, check=True)
        return target.read_text()

    before = tomllib.loads(config)
    rendered = apply(config)
    after = tomllib.loads(rendered)
    for table, values in MANAGED_SETTINGS.items():
        for key, value in values.items():
            assert after["settings"][table][key] == value
    for config_table in (before, after):
        settings = config_table.get("settings", {})
        for table, values in MANAGED_SETTINGS.items():
            for key in values:
                settings.get(table, {}).pop(key, None)
            if settings.get(table) == {}:
                del settings[table]
        if settings == {}:
            config_table.pop("settings", None)
    assert after == before
    assert apply(rendered) == rendered


def test_settings_modifier_rejects_invalid_input_without_output(
    modifier: tuple[list[str], Path],
) -> None:
    command, target = modifier
    invalid = '[settings.proxy]\nhost = "unterminated'
    target.write_text(invalid)
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    assert result.returncode != 0
    assert result.stdout == ""
    assert target.read_text() == invalid


def test_pitchfork_setup_starts_supervisor_and_trusts_ca(linux: Shell) -> None:
    result = linux("""
host_has_systemd() { return 0; }
SKIP_MANAGED_TOOLS=false
USER=tester
XDG_STATE_HOME="$HOME/state"
mkdir -p "$XDG_STATE_HOME/pitchfork/proxy"
touch "$XDG_STATE_HOME/pitchfork/proxy/ca.pem"
run_task() { shift; [[ $1 != --sudo ]] || shift; printf '%s\\n' "$*" >> "$HOME/calls"; }
mise() { [[ "$*" == "which pitchfork" ]] && printf 'pitchfork\\n'; }
pitchfork() {
  case "$1 $2" in
  'supervisor status') return 1 ;;
  'proxy status') printf 'Trusted: no\\n' ;;
  esac
}
phase_pitchfork
cat "$HOME/calls"
""")
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.splitlines()[-4:] == [
        "loginctl enable-linger tester",
        "pitchfork boot enable",
        "pitchfork supervisor start",
        "pitchfork proxy trust",
    ]
