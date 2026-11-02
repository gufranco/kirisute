#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_args_switch() {
  case "$1" in
  --dry-run) KS_DRY_RUN=yes ;;
  --info) KS_INFO=yes ;;
  --json) KS_JSON=yes ;;
  --recursive) KS_RECURSIVE=yes ;;
  --verify) KS_VERIFY=yes ;;
  --no-verify) KS_VERIFY=no ;;
  --backup) KS_BACKUP=yes ;;
  --no-backup) KS_BACKUP=no ;;
  *) return 1 ;;
  esac
}

ks_args_one() {
  ks_args_switch "$1" && return 0
  case "$1" in
  --) KS_ARGS_DONE=yes ;;
  --*=*)
    ks_cli_hint "unknown option '${1%%=*}'"
    return 1
    ;;
  -?*)
    ks_cli_hint "unknown option '$1'"
    return 1
    ;;
  '')
    ks_cli_hint "the file name is empty"
    return 1
    ;;
  *) KS_INPUTS=$((KS_INPUTS + 1)) ;;
  esac
}

ks_args_parse() {
  KS_ARGS_DONE=no
  for ks_ap_arg in "$@"; do
    if [ "${KS_ARGS_DONE}" = no ]; then
      ks_args_one "${ks_ap_arg}" || return 1
    elif [ -n "${ks_ap_arg}" ]; then
      KS_INPUTS=$((KS_INPUTS + 1))
    else
      ks_cli_hint "the file name is empty"
      return 1
    fi
  done
}

ks_args_env() {
  ks_ae_value="$2"
  case "${ks_ae_value}" in
  yes | no) printf '%s\n' "${ks_ae_value}" ;;
  *)
    ks_error "$1 must be yes or no, got: ${ks_ae_value}"
    return 1
    ;;
  esac
}

ks_args_settings() {
  if [ -z "${KS_VERIFY}" ]; then
    KS_VERIFY="$(ks_args_env KIRISUTE_VERIFY "${KIRISUTE_VERIFY:-no}")" || return 1
  fi
  if [ -z "${KS_BACKUP}" ]; then
    KS_BACKUP="$(ks_args_env KIRISUTE_BACKUP "${KIRISUTE_BACKUP:-no}")" || return 1
  fi
  return 0
}

ks_args_inputs() {
  ks_ai_mode="$1"
  shift
  KS_ARGS_DONE=no
  for ks_ai_arg in "$@"; do
    if [ "${KS_ARGS_DONE}" = no ]; then
      case "${ks_ai_arg}" in
      --) KS_ARGS_DONE=yes ;;
      -?*) : ;;
      *) ks_walk_input "${ks_ai_mode}" "${ks_ai_arg}" ;;
      esac
      continue
    fi
    ks_walk_input "${ks_ai_mode}" "${ks_ai_arg}"
  done
}
