#!/usr/bin/env bash

apply_dotfiles() {
  local -a source_args=(--source "$DOTFILES_DIR") tty_args=()
  if [[ ${DOTFILES_ASSUME_YES:-false} == true || ! -t 0 || ! -t 1 ]]; then
    tty_args=(--no-tty)
  fi
  # .chezmoi.toml.tmpl holds machine data such as isWSL and isLima. init
  # regenerates the config, so a direct setup run and a changed template both
  # get current data.
  printf 'chezmoi %s\n' "${source_args[*]} ${tty_args[*]} init"
  chezmoi "${source_args[@]}" "${tty_args[@]}" init
  [[ ${#tty_args[@]} == 0 ]] || tty_args+=(--error-on-conflict)
  printf 'chezmoi %s\n' "${source_args[*]} ${tty_args[*]} apply"
  chezmoi "${source_args[@]}" "${tty_args[@]}" apply
}
