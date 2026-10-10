#!/bin/bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { printf 'this setup supports macOS only\n' >&2; exit 1; }
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=setup/common.sh
source "$DOTFILES_DIR/setup/common.sh"
cd "$HOME"

# mise owns every CLI; brew stays out of the bootstrap.
export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"

install_script() {
  local url="$1" script rc=0
  shift
  script="$(mktemp "${TMPDIR:-/tmp}/dotfiles-script-XXXXXX")"
  if curl -fsSL --retry 3 --connect-timeout 10 "$url" -o "$script"; then
    sh "$script" "$@" || rc=$?
  else
    rc=$?
  fi
  rm -f -- "$script"
  return "$rc"
}

# CLT provides git and the compiler toolchain mise-built languages need.
if ! xcode-select -p &> /dev/null; then
  xcode-select --install
fi
if ! command -v git &> /dev/null; then
  echo "waiting for the Xcode CLT install (accept the dialog)" >&2
  for _ in $(seq 1 30); do
    command -v git &> /dev/null && break
    sleep 10
  done
  command -v git &> /dev/null || {
    echo "Xcode CLT is still installing. Re-run bootstrap.sh later." >&2
    exit 1
  }
fi

if ! command -v mise &> /dev/null; then
  install_script https://mise.run
fi

# github: backends clone private forks. Auth must exist before 'mise install'.
export PATH="$HOME/.local/share/mise/shims:$PATH"
mise install --quiet github-cli@latest
if ! mise exec --quiet github-cli@latest -- gh auth status &> /dev/null; then
  if [[ ${DOTFILES_ASSUME_YES:-false} != true ]] && [ -t 1 ]; then
    mise exec --quiet github-cli@latest -- gh auth login --web --git-protocol https
  else
    echo "gh is not authenticated. Run 'gh auth login --web', then 'mise install'." >&2
  fi
fi

# nix: backends in the mise config need Nix. The Nix installer rejects
# --no-daemon on macOS. The daemon install asks for sudo, creates the /nix APFS
# volume, and hooks /etc/zshrc.
nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if ! command -v nix &> /dev/null && [[ ! -e $nix_profile ]]; then
  install_script https://nixos.org/nix/install --daemon --yes
fi
if [[ -e $nix_profile ]]; then
  # shellcheck source=/dev/null
  . "$nix_profile"
fi
command -v nix &> /dev/null || {
  echo "nix is not on PATH. Open a new shell and re-run bootstrap.sh." >&2
  exit 1
}

apply_dotfiles
mise install --quiet
