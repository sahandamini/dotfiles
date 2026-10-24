# Dotfiles

Personal machine setup managed with chezmoi and mise.

## Bootstrap

Run the bootstrap script for your OS. The shell script detects the OS and runs
`setup/linux.sh` or `setup/darwin.sh`.

macOS and Linux (the Lima VM, WSL, servers):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/bootstrap.sh)
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/sahandamini/dotfiles/main/bootstrap.ps1 | iex
```

The repo lives at `~/.local/share/chezmoi`, chezmoi's default source directory.
Chezmoi links `~/dotfiles` to it.

### Options

Pass bootstrap options after the command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/bootstrap.sh) --profile core --yes
```

Run `bootstrap.sh --help` to list options.

- Linux core installs base packages, mise, Nix, dotfiles, and the login shell.
- Linux full also installs the managed tools. An interactive checklist selects
  the optional steps: Docker, Tailscale, Pitchfork, Caddy (Lima VM only), T3
  Code, and WSL Windows PATH and automount (WSL only, off by default). Without a
  terminal, select them with `--with docker,tailscale,pitchfork,caddy,t3`. An
  explicit `--with` list replaces the default selection.
- On WSL, the checklist does not preselect Docker. Docker Desktop for Windows
  provides the client, and setup skips the engine, group, and service steps.
- T3 Code installs the latest release when its service is missing or broken.
  After that, `t3 update` moves it to new releases.
- `--skip-managed-tools` skips the managed tool catalog during setup.
- The summary lists each installed CLI that is not signed in, with its login
  command.

### macOS

`setup/darwin.sh` installs the Xcode CLT and mise, signs in to GitHub, installs
Nix (multi-user, asks for sudo) for the `nix:` tools, applies the dotfiles, and
runs `mise install`.

### Windows

Windows development runs in WSL. Run the Linux bootstrap inside WSL. WSL keeps
its default settings: NAT networking with DNS tunneling. The dotfiles manage no
`.wslconfig`, `/etc/wsl.conf`, or `/etc/hosts`.

Run `bootstrap.ps1` on Windows for the WezTerm config. It installs Git, mise,
chezmoi, and opencode on Windows, then applies only the files that Windows
programs read: `.ssh`, the opencode and WezTerm configs, and `AGENTS.md`.

## Layout

| Path                                      | What it is                               |
| ----------------------------------------- | ---------------------------------------- |
| `bootstrap.sh`, `bootstrap.ps1`           | entry points that fetch the source       |
| `setup/`                                  | macOS and Linux machine setup            |
| `tests/`                                  | setup regression and smoke tests         |
| `home/`                                   | chezmoi source state for `$HOME`         |
| `home/.chezmoidata.toml`                  | shared data: app domain, Lima VM, themes |
| `mise-global/config.toml`                 | global mise settings and language runtimes |
| `mise-global/conf.d/*.toml`               | global tools, grouped by purpose         |
| `home/dot_config/mise/create_mise.lock`   | first lockfile for a new machine         |
| `nvim/lazy-lock.json`                     | nvim plugin versions for every machine   |

Change the terminal theme (Ghostty, WezTerm, Herdr, nvim) in
`home/.chezmoidata.toml`.

## Commands

Run from the repo root:

```bash
mise run check                    # shellcheck, ruff, and basedpyright
mise run test                     # setup regression tests
mise run test:e2e                 # real Ubuntu setup in Docker
mise run debug:linux              # local setup in a fresh Ubuntu container
```

Global (works from any directory):

```bash
mise run app:new                  # create an app from a template
```

`app:new` asks for a template (`tanstack`, `astro`, or `empty`), an app name,
and whether to create a public GitHub repo. It checks the name and the repo
before it changes anything. Then it:

1. Scaffolds `~/apps/<name>` with `copier` and commits it on `main`.
2. Creates the GitHub repo and pushes `main`, when you chose GitHub.
3. Allows squash merges only and deletes branches after merge.
4. Adds a `main` ruleset: changes land through PRs with linear history and
   resolved threads, force-push and deletion are blocked, and the template's CI
   checks must pass. Repo admins can bypass it.

GitHub Free has no rulesets on private repos, so `app:new` creates public repos
only. The templates live in their own fork:
[sahandamini/tanstack-template](https://github.com/sahandamini/tanstack-template).
Its README describes the upstream sync.

List everything with `mise tasks --all`.

## Staying current

Run `dotfiles update` on each machine. `dotfiles` alone opens the repo. The
update runs `~/.local/bin/dotfiles-update`, which does these steps in order:

1. Update mise (`mise self-update`). A newer lockfile can need a newer mise.
2. Pull the repo and apply it (`chezmoi update`). This step also pulls the
   nvim plugin versions that other machines committed.
3. Install new tools and upgrade the rest (`mise install`, `mise up`).
4. Update T3 Code (`t3 update --yes`) on machines that run its service.
5. Update the nvim plugins (`Lazy! update`). `~/.config/nvim/lazy-lock.json`
   links to `nvim/lazy-lock.json` in the repo, so Lazy writes the new versions
   into the repo.
6. Check the plugins. Headless nvim loads every plugin. Any `Error` or
   `E<number>:` line in its output fails the check.
7. If the check passes and the plugin versions changed, commit only
   `nvim/lazy-lock.json` as "Update nvim plugins" and push it.
8. If the check fails, restore the previous lockfile, run `Lazy! restore`, and
   commit nothing. The script prints the error and exits with status 1.

The check catches plugins that fail at startup. It cannot catch a bug that
shows only when you use a feature. To roll back the plugins after such a bug:

```bash
git -C ~/.local/share/chezmoi log --oneline -- nvim/lazy-lock.json
git -C ~/.local/share/chezmoi checkout <good-commit> -- nvim/lazy-lock.json
nvim --headless '+Lazy! restore' +qa
```

Then commit the restored lockfile, so other machines get the rollback.

chezmoi writes `~/.config/mise/mise.lock` only when it is missing. After that,
each machine owns its mise lockfile.

## Updating tools

chezmoi writes `~/.config/mise/mise.lock` only when it is missing. After that,
each machine owns its lockfile, and `mise up` upgrades it there.

To refresh the lockfile for new machines, regenerate it with entries for all
four platforms, copy it into the repo, then commit it:

```bash
GITHUB_TOKEN=$(gh auth token) mise lock --global --platform linux-arm64,linux-x64,macos-arm64,macos-x64
cp ~/.config/mise/mise.lock "$(chezmoi source-path ~/.config/mise/mise.lock)"
```

`~/.config/mise/config.toml` and `~/.config/mise/conf.d` link to
`mise-global/` in the repo. `mise use -g` and manual edits change the tracked
files, so commit them. `mise outdated --bump` lists pinned versions to bump.
The `mise-global/` directory sits outside the mise search paths, so mise does
not load it as a project config.

## Lima VM

Create the `devbox` instance from the managed template (Lima 2.2.0 or newer,
no host mounts, SSH on port 60022):

```bash
limactl create --name devbox ~/.config/lima/devbox.yaml -y
limactl start devbox
ssh devbox
```

Copy files between the Mac and the VM with `limactl copy`. Update the VM's
Tailscale address in `home/.chezmoidata.toml` if it changes.

## App URLs

Caddy on the VM serves `https://<name>.lab.sahandamini.dev` with a wildcard
Let's Encrypt certificate, and proxies to Pitchfork on port 9443. Caddy proves
domain control with a Porkbun DNS record, so it needs a Porkbun API key.

1. In Porkbun, add an A record `*.lab` that points to the VM's Tailscale IP.
2. In Porkbun, create an API key. Turn on API access for `sahandamini.dev` only.
3. Run the bootstrap on the VM and select Caddy. Setup asks for the key, writes
   it to `~/.config/caddy-lab/env` (mode 600), and starts Caddy.

To change the key later, delete `~/.config/caddy-lab/env` and run the bootstrap
again. Read the logs with `journalctl -u caddy-lab -f`.

## Updating from upstream

See [UPDATING.md](UPDATING.md) for the review, tool-selection, and sync process.
