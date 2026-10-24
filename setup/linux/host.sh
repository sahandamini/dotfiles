#!/usr/bin/env bash

# Host facts. Tests fake a host through the HOST_* paths.
: "${HOST_PROC_VERSION:=/proc/version}"
: "${HOST_SYSTEMD_DIR:=/run/systemd/system}"
: "${HOST_OS_RELEASE:=/etc/os-release}"
: "${HOST_LIMA_AGENT:=/usr/local/bin/lima-guestagent}"

host_is_wsl() {
  grep -qi microsoft "$HOST_PROC_VERSION" 2> /dev/null
}

host_has_systemd() {
  [[ -d $HOST_SYSTEMD_DIR ]]
}

host_is_lima() {
  [[ -x $HOST_LIMA_AGENT ]]
}
