# Dotfiles

Personal machine setup managed with chezmoi and mise.

Bootstrap a fresh machine with:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/install.sh)
```

## Layout

| Path                               | What it is                                       |
| ---------------------------------- | ------------------------------------------------ |
| `home/`                            | chezmoi source state for `$HOME`                 |
| `apps/tanstack`                    | copier template scaffolded by `new-tanstack-app` |
| `home/dot_config/mise/config.toml` | machine-wide toolchains and global tasks         |

Tools reach PATH through mise and repository-local tool packages.

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

List everything with `mise tasks --all`.

## Updating from upstream

See [UPDATING.md](UPDATING.md) for the review, tool-selection, and sync process.

Create the managed Lima instance configuration with:

```bash
limactl create --name default ~/.config/lima/default.yaml -y
```
