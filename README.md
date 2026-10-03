# Dotfiles

Personal machine setup managed with chezmoi and mise.

## Bootstrap

Linux (the Lima VM, WSL, servers):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/install.sh)
```

macOS:

```bash
xcode-select --install   # git; accept the dialog first
git clone https://github.com/sahandamini/dotfiles.git ~/dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --source ~/dotfiles --apply
```

The first apply on macOS runs `run_once_after_install-darwin.sh`. It installs
mise, signs in to GitHub, installs Nix (multi-user, asks for sudo) for the
`nix:` tools, and runs `mise install`. mise then manages chezmoi itself.

Always pass `--source ~/dotfiles` to `chezmoi init`. A bare `chezmoi init`
creates an empty source directory instead of using this repo.

## Layout

| Path                               | What it is                                       |
| ---------------------------------- | ------------------------------------------------ |
| `home/`                            | chezmoi source state for `$HOME`                 |
| `home/.chezmoidata/`               | shared data: Lima VM identity, terminal themes   |
| `home/dot_config/mise/config.toml` | machine-wide toolchains and global tasks         |
| `home/dot_config/mise/mise.lock`   | pinned versions for macOS and Linux              |

Tools reach PATH through mise and repository-local tool packages. Change the
terminal theme (Ghostty, WezTerm, Herdr, nvim) in
`home/.chezmoidata/themes.toml`.

## Commands

Run from the repo root:

```bash
mise run check                    # lint + test every tool
mise run install                  # install personal tools onto PATH
mise run apply                    # update $HOME from the source state
```

Global (works from any directory):

```bash
mise run new-tanstack-app <dir>   # scaffold a new TanStack Start app
```

The app template lives in its own fork:
[sahandamini/tanstack-template](https://github.com/sahandamini/tanstack-template).
Its README describes the upstream sync.

List everything with `mise tasks --all`.

## Lima VM

Create the default instance from the managed template (no host mounts, SSH on
port 60022):

```bash
limactl create --name default ~/.config/lima/default.yaml -y
limactl start default
ssh lima
```

From inside the VM, `ssh mac` reaches the Mac. Update the VM's Tailscale
address in `home/.chezmoidata/vm.toml` if it changes.

## Updating from upstream

See [UPDATING.md](UPDATING.md) for the review, tool-selection, and sync process.
