# Dotfiles

Personal machine setup managed with GNU stow and mise.

Bootstrap a fresh machine with:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/install.sh)
```

## Layout

| Path | What it is |
| --- | --- |
| `.config/`, `.zshrc`, … | stowed into `$HOME` |
| `tools/` | one directory per CLI capability (`dev`, `imgview`, `pix`) |
| `apps/tanstack` | copier template scaffolded by `new-tanstack-app` |
| `.config/mise/config.toml` | machine-wide toolchains and global tasks |

Tools reach PATH two ways: Python CLIs use editable uv tools, and pix uses an
install-task launcher.

## Commands

Run from the repo root:

```bash
mise run check                    # lint + test every tool
mise run install                  # install personal tools onto PATH
mise run restow                   # re-link dotfiles into $HOME
```

Global (works from any directory):

```bash
mise run new-tanstack-app <dir>   # scaffold a new TanStack Start app
```

List everything with `mise tasks --all`.
