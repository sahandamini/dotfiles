#!/usr/bin/env bash

docker_installed() {
  command -v docker > /dev/null 2>&1
}

tailscale_installed() {
  command -v tailscale > /dev/null 2>&1 \
    || [[ "$(dpkg-query -W -f='${Status}' tailscale 2> /dev/null)" == 'install ok installed' ]]
}

caddy_installed() {
  systemctl is-enabled caddy-lab.service > /dev/null 2>&1 \
    && porkbun_keys_present "$HOME/.config/caddy-lab/env"
}

t3_service_installed() {
  [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/t3code.service" ]]
}

setup_step_label() {
  case "$1" in
  mise_tools) printf 'Developer tools' ;;
  docker) printf 'Docker' ;;
  tailscale) printf 'Tailscale' ;;
  pitchfork) printf 'Pitchfork' ;;
  caddy) printf 'Caddy' ;;
  t3) printf 'T3 Code' ;;
  esac
}

setup_step_installed() {
  case "$1" in
  docker) docker_installed ;;
  tailscale) tailscale_installed ;;
  pitchfork) [[ -n "$(setup_step_version pitchfork)" ]] ;;
  caddy) caddy_installed ;;
  t3) t3_service_installed ;;
  *) return 1 ;;
  esac
}

setup_step_version() {
  local field=1 line version
  local -a probe=() fields=()
  case "$1" in
  docker) probe=(docker --version); field=2 ;;
  tailscale) probe=(tailscale version); field=0 ;;
  pitchfork) probe=(pitchfork --version) ;;
  caddy) probe=("$HOME/.local/bin/caddy" version); field=0 ;;
  t3)
    if [[ -f "$HOME/.t3/runtime/service-state.json" ]]; then
      probe=(jq -er '.activeVersion // empty' "$HOME/.t3/runtime/service-state.json")
    else
      probe=(t3 --version)
    fi
    field=0
    ;;
  *) return 0 ;;
  esac
  # Version probes must not trigger downloads through mise shims.
  line="$(MISE_AUTO_INSTALL=false MISE_OFFLINE=true MISE_NO_ENV=true MISE_NO_HOOKS=true \
    timeout 5 "${probe[@]}" 2> /dev/null)" || return 0
  read -r -a fields <<< "$line"
  version="${fields[$field]:-}"
  [[ $version =~ ^v?[0-9] ]] || return 0
  printf '%s' "${version%,}"
}

phase_docker() {
  if ! docker_installed; then
    run_task 'Creating the Docker key directory' --sudo install -m 0755 -d /etc/apt/keyrings
    run_task 'Downloading the Docker key' --sudo curl -fsSL --retry 3 \
      https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    run_task 'Setting Docker key permissions' --sudo chmod a+r /etc/apt/keyrings/docker.asc
    # shellcheck source=/dev/null
    . /etc/os-release
    run_task 'Adding the Docker repository' --sudo tee /etc/apt/sources.list.d/docker.list \
      <<< "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable"
    run_task 'Updating the Docker package index' --sudo apt-get update
    run 'Installing Docker' --sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  show_version Docker 2 docker --version
  if ! id -nG "$USER" | grep -qw docker; then
    run_task 'Adding user to docker group' --sudo usermod -aG docker "$USER"
    NOTES+=('Docker group: log out and back in to run docker without sudo')
  fi
  if [[ $HAS_SYSTEMD == true ]]; then
    run_task 'Enabling Docker' --sudo systemctl enable --now docker
  else
    detail 'no systemd; start dockerd manually with: sudo dockerd'
  fi
}

phase_tailscale() {
  if [[ $HAS_SYSTEMD == false ]]; then
    detail 'no systemd; skipping Tailscale service setup'
    return
  fi
  need_sudo
  if ! tailscale_installed; then
    run_script 'Installing Tailscale' https://tailscale.com/install.sh sh
  fi
  show_version Tailscale 0 tailscale version
  run_task 'Enabling tailscaled' --sudo systemctl enable --now tailscaled
  if root_plain tailscale status > /dev/null 2>&1; then
    ok 'Tailscale authenticated'
  elif [[ $INTERACTIVE == true ]]; then
    detail 'Open the Tailscale login link below (timeout: 3 minutes)'
    if ! root_plain timeout 180 tailscale up; then
      warn "tailscale auth not completed; run 'sudo tailscale up' after install"
      return
    fi
  else
    warn "tailscale not authenticated; run 'sudo tailscale up' after install"
    return
  fi
  run_task 'Enabling Tailscale SSH' --sudo tailscale set --ssh=true || warn 'Tailscale SSH not enabled; check tailnet ACLs'
  run_task 'Setting Tailscale operator' --sudo tailscale set --operator="$USER" || warn 'Tailscale operator not set'
}

phase_pitchfork() {
  if [[ $HAS_SYSTEMD == false ]]; then
    detail 'no systemd; skipping Pitchfork URL setup'
    return
  fi
  if [[ $SKIP_MANAGED_TOOLS == true ]]; then
    run 'Installing Pitchfork prerequisite' --live mise install pitchfork
  fi
  detail 'Pitchfork installs a boot service and a local TLS certificate authority'
  run_task 'Configuring Pitchfork URLs' mise -C "$DOTFILES_DIR" run setup-pitchfork 127.0.0.1
}

porkbun_keys_present() {
  grep -qs '^PORKBUN_API_KEY=.' "$1" && grep -qs '^PORKBUN_API_SECRET_KEY=.' "$1"
}

prompt_porkbun_keys() {
  local env_file="$1" key secret
  detail 'Caddy needs a Porkbun API key for its wildcard certificate'
  key="$(gum_ui input --password --header 'Porkbun API key' < /dev/tty 2> /dev/tty)" || return $?
  secret="$(gum_ui input --password --header 'Porkbun secret API key' < /dev/tty 2> /dev/tty)" || return $?
  [[ -n $key && -n $secret ]] || return 1
  mkdir -p "${env_file%/*}"
  (
    umask 077
    printf 'PORKBUN_API_KEY=%s\nPORKBUN_API_SECRET_KEY=%s\n' "$key" "$secret" > "$env_file.tmp"
    mv -f -- "$env_file.tmp" "$env_file"
  )
}

phase_caddy() {
  if [[ $IS_LIMA == false || $HAS_SYSTEMD == false ]]; then
    detail 'not a Lima VM with systemd; skipping Caddy'
    return
  fi
  local env_file="$HOME/.config/caddy-lab/env"
  if ! porkbun_keys_present "$env_file"; then
    if [[ $INTERACTIVE == true ]] && prompt_porkbun_keys "$env_file"; then
      ok 'Porkbun keys' 'saved'
    else
      warn "Caddy: write the Porkbun API keys to $env_file, then run 'mise run setup-caddy'"
    fi
  fi
  need_sudo
  run_task 'Configuring Caddy' mise -C "$DOTFILES_DIR" run setup-caddy
}

t3_opencode_shim() {
  printf '%s/shims/opencode' "${MISE_DATA_DIR:-$HOME/.local/share/mise}"
}

write_t3_settings() {
  # A versioned install path breaks when mise prunes that version after an
  # upgrade. The shim always runs the current version.
  # Home and binary paths can contain shell quotes.
  # shellcheck disable=SC2016
  run_task 'Writing T3 Code settings' bash -Eeuo pipefail -c '
    mkdir -p "${2%/*}"
    settings_tmp="$(mktemp "$2.XXXXXX")"
    trap "rm -f -- \"\$settings_tmp\"" EXIT
    if [[ -f "$2" ]]; then
      jq --arg b "$1" ".providers.opencode.binaryPath = \$b" "$2" > "$settings_tmp"
    else
      jq -n --arg b "$1" "{providers: {opencode: {enabled: true, binaryPath: \$b}}}" > "$settings_tmp"
    fi
    mv -- "$settings_tmp" "$2"
  ' _ "$1" "$2"
}

t3_settings_current() {
  [[ -f "$2" ]] && jq -e --arg b "$1" '.providers.opencode.binaryPath == $b' "$2" > /dev/null 2>&1
}

phase_t3() {
  if [[ $HAS_SYSTEMD == false ]]; then
    detail 'no systemd; skipping T3 Code'
    return
  fi
  if [[ $SKIP_MANAGED_TOOLS == true ]]; then
    run 'Installing T3 Code prerequisites' --live mise install node opencode jq
  fi
  detail 'T3 Code installs a systemd user service for pairing remote devices'
  local opencode_bin t3_settings node_bin_dir installed=false
  opencode_bin="$(t3_opencode_shim)"
  t3_settings="$HOME/.t3/userdata/settings.json"
  if ! t3_settings_current "$opencode_bin" "$t3_settings"; then
    write_t3_settings "$opencode_bin" "$t3_settings"
  fi
  node_bin_dir="$(dirname "$(mise -C "$DOTFILES_DIR" which node)")"
  if [[ ! -x /usr/bin/g++ ]]; then
    run_task 'Installing build tools' --sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
  fi
  ! t3_service_installed || installed=true
  # service install also repairs an existing service. A release can need a
  # newer launcher than an old pin provides, so install the latest release.
  run_task 'Installing T3 Code' env PATH="$node_bin_dir:/usr/bin:/bin" CC=/usr/bin/gcc CXX=/usr/bin/g++ \
    NPM_CONFIG_CACHE="$HOME/.cache/npm-t3" "$node_bin_dir/npx" --yes t3@latest service install
  if [[ $installed == false ]]; then
    NOTES+=($'Pair a device:\n  t3 pair --tailscale --tailscale-serve-port 8443\n  then scan the QR code')
  fi
}
