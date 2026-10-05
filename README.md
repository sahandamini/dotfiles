# Dotfiles

Personal machine setup managed with chezmoi and mise.

## Bootstrap

Run the wrapper on macOS or Linux (the Lima VM, WSL, servers). It detects the
OS and runs `install-mac.sh` or `install-linux.sh`. Options pass through; run it
with `--help` to list them.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sahandamini/dotfiles/main/install.sh)
```

The repo lives at `~/.local/share/chezmoi`, chezmoi's default source directory.
Chezmoi links `~/dotfiles` to it.

On macOS, the first apply runs `run_once_after_install-darwin.sh`. It installs
the Xcode CLT and mise, signs in to GitHub, installs Nix (multi-user, asks for
sudo) for the `nix:` tools, and runs `mise install`. mise then manages chezmoi
itself.

## Layout

| Path                               | What it is                                       |
| ---------------------------------- | ------------------------------------------------ |
| `home/`                            | chezmoi source state for `$HOME`                 |
| `home/.chezmoidata.toml`           | shared data: app domain, Lima VM, themes         |
| `home/dot_config/mise/config.toml` | machine-wide toolchains and global tasks         |
| `home/dot_config/mise/mise.lock`   | pinned versions for macOS and Linux              |

Tools reach PATH through mise and repository-local tool packages. Change the
terminal theme (Ghostty, WezTerm, Herdr, nvim) in `home/.chezmoidata.toml`.

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

Create the `devbox` instance from the managed template (no host mounts, SSH on
port 60022):

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
3. On the VM, write the key to `~/.config/caddy-lab/env` (mode 600):

   ```bash
   umask 077; read -rsp 'API key: ' k; echo; read -rsp 'Secret key: ' s; echo
   printf 'PORKBUN_API_KEY=%s\nPORKBUN_API_SECRET_KEY=%s\n' "$k" "$s" > ~/.config/caddy-lab/env; unset k s
   ```

4. Run `mise run setup-caddy`. Read the logs with `journalctl -u caddy-lab -f`.

## Updating from upstream

See [UPDATING.md](UPDATING.md) for the review, tool-selection, and sync process.
