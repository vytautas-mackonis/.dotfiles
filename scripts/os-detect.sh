#!/usr/bin/env bash

# Sets OS_FAMILY (macos|linux|unknown), OS_DISTRO (ubuntu|arch|unknown),
# OS_ENV (native|wsl), and OS_NAME. Source this file from other scripts.

OS_FAMILY=unknown
OS_DISTRO=unknown
OS_ENV=native
OS_NAME=unknown

case "$(uname -s)" in
  Darwin)
    OS_FAMILY=macos
    OS_NAME=macOS
    ;;
  Linux)
    OS_FAMILY=linux
    if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
      OS_ENV=wsl
    elif [[ -n "${WSL_INTEROP:-}" ]]; then
      OS_ENV=wsl
    fi
    if [[ -r /etc/os-release ]]; then
      # shellcheck disable=SC1091
      source /etc/os-release
      OS_NAME=${NAME:-Linux}
      case "${ID:-}" in
        ubuntu|debian)
          OS_DISTRO=ubuntu
          ;;
        arch|cachyos)
          OS_DISTRO=arch
          ;;
      esac
    else
      OS_NAME=Linux
    fi
    ;;
esac

export OS_FAMILY OS_DISTRO OS_ENV OS_NAME
