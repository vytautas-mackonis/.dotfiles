#!/usr/bin/env bash

# Shared setup for dotfiles scripts. Source this file; do not execute it.
# Exports:
#   DOTFILES_DIR - absolute path to this dotfiles checkout/install copy
#   OS_FAMILY, OS_DISTRO, OS_ENV, OS_NAME - detected platform details

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'scripts/common.sh must be sourced from bash.\n' >&2
  return 1 2>/dev/null || exit 1
fi

_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(cd -- "$_COMMON_SCRIPT_DIR/.." && pwd)

# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/os-detect.sh"

export DOTFILES_DIR OS_FAMILY OS_DISTRO OS_ENV OS_NAME
unset _COMMON_SCRIPT_DIR
