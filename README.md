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
  the optional services: Docker, Tailscale, Pitchfork, Caddy (Lima VM only), and
  T3 Code. Without a terminal, select them with
  `--with docker,tailscale,pitchfork,caddy,t3`.
- `--skip-managed-tools` skips the managed tool catalog during setup.
- The summary lists each installed CLI that is not signed in, with its login
  command.

### macOS

`setup/darwin.sh` installs the Xcode CLT and mise, signs in to GitHub, installs
Nix (multi-user, asks for sudo) for the `nix:` tools, applies the dotfiles, and
runs `mise install`.

### Windows

Windows development runs in WSL. Run the Linux bootstrap inside WSL. Its
dotfiles apply also writes `.wslconfig` and the WezTerm config on the Windows
side.

`bootstrap.ps1` is optional. It installs Git, mise, chezmoi, and opencode on
Windows, then applies only the files that Windows programs read: `.ssh`, the
opencode and WezTerm configs, and `AGENTS.md`. After it runs, native Windows
chezmoi owns the WezTerm config, and WSL stops writing it.

## Layout

| Path                                      | What it is                               |
| ----------------------------------------- | ---------------------------------------- |
| `bootstrap.sh`, `bootstrap.ps1`           | entry points that fetch the source       |
| `setup/`                                  | macOS and Linux machine setup            |
| `tests/`                                  | setup regression and smoke tests         |
| `home/`                                   | chezmoi source state for `$HOME`         |
| `home/.chezmoidata.toml`                  | shared data: app domain, Lima VM, themes |
| `home/dot_config/mise/config.toml`        | machine-wide toolchains and global tasks |
| `home/dot_config/mise/create_mise.lock`   | first lockfile for a new machine         |

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
mise run new-tanstack-app <dir>   # scaffold a new TanStack Start app
```

The app template lives in its own fork:
[sahandamini/tanstack-template](https://github.com/sahandamini/tanstack-template).
Its README describes the upstream sync.

List everything with `mise tasks --all`.

## Staying current

Run `dotfiles update` on each machine. It updates mise, pulls and applies the
dotfiles (`chezmoi update --init`), installs new tools, and upgrades the rest
(`mise up`). `dotfiles` alone opens the repo.

## Updating tools

chezmoi writes `~/.config/mise/mise.lock` only when it is missing. After that,
each machine owns its lockfile, and `mise up` upgrades it there.

To refresh the lockfile for new machines, regenerate it with entries for all
four platforms, copy it into the repo, then commit it:

```bash
GITHUB_TOKEN=$(gh auth token) mise lock --global --platform linux-arm64,linux-x64,macos-arm64,macos-x64
cp ~/.config/mise/mise.lock "$(chezmoi source-path ~/.config/mise/mise.lock)"
```

Bump pinned versions (`mise outdated --bump` lists them) in
`home/dot_config/mise/config.toml`, not with `mise use -g` on a machine.

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
