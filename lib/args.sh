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
  --best)
    KS_BEST=yes
    KS_COMPRESS_SET=yes
    ;;
  *) return 1 ;;
  esac
}

ks_args_takes_value() {
  case " ${KS_VALUE_OPTIONS} " in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

ks_args_value() {
  KS_COMPRESS_SET=yes
  case "$1" in
  --format) ks_args_format "$1" "$2" ;;
  --block) ks_args_block "$1" "$2" ;;
  *) ks_args_cost "$1" "$2" ;;
  esac
}

ks_args_format() {
  case "$2" in
  cso | cso2 | zso) KS_FORMAT="$2" ;;
  *)
    ks_error "$1 must be cso, cso2 or zso, got: $2"
    return 1
    ;;
  esac
}

ks_args_block() {
  case "$2" in
  2048 | 4096 | 8192 | 16384) KS_BLOCK="$2" ;;
  *)
    ks_error "$1 must be 2048, 4096, 8192 or 16384, got: $2"
    return 1
    ;;
  esac
}

ks_args_cost() {
  case "$2" in
  '' | *[!0-9]*) ks_ac_ok=no ;;
  *) ks_ac_ok=yes ;;
  esac
  if [ "${ks_ac_ok}" = no ] || [ "$2" -gt 100 ]; then
    ks_error "$1 must be a whole number from 0 to 100, got: $2"
    return 1
  fi
  KS_LZ4_COST="$2"
  [ "$1" != --lz4-cost ] || KS_LZ4_SET=yes
}

ks_args_one() {
  ks_args_switch "$1" && return 0
  case "$1" in
  --) KS_ARGS_DONE=yes ;;
  --*=*)
    if ks_args_takes_value "${1%%=*}"; then
      ks_args_value "${1%%=*}" "${1#*=}"
      return
    fi
    ks_cli_hint "unknown option '${1%%=*}'"
    return 1
    ;;
  -?*)
    if ks_args_takes_value "$1"; then
      KS_ARGS_PENDING="$1"
      return 0
    fi
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
  KS_ARGS_PENDING=""
  for ks_ap_arg in "$@"; do
    if [ -n "${KS_ARGS_PENDING}" ]; then
      ks_args_value "${KS_ARGS_PENDING}" "${ks_ap_arg}" || return 1
      KS_ARGS_PENDING=""
    elif [ "${KS_ARGS_DONE}" = no ]; then
      ks_args_one "${ks_ap_arg}" || return 1
    elif [ -n "${ks_ap_arg}" ]; then
      KS_INPUTS=$((KS_INPUTS + 1))
    else
      ks_cli_hint "the file name is empty"
      return 1
    fi
  done
  [ -n "${KS_ARGS_PENDING}" ] || return 0
  ks_cli_hint "option '${KS_ARGS_PENDING}' needs a value"
  return 1
}

ks_args_command_options() {
  if [ "${KS_MODE}" != compress ] && [ "${KS_COMPRESS_SET}" = yes ]; then
    ks_cli_hint "--format, --block, --lz4-cost and --best apply only to compress"
    return 1
  fi
  [ "${KS_MODE}" != trim ] || return 0
  if [ "${KS_INFO}" = yes ]; then
    ks_cli_hint "--info does not apply to ${KS_MODE}"
    return 1
  fi
  if [ -n "${KS_VERIFY}" ]; then
    ks_cli_hint "--verify and --no-verify do not apply to ${KS_MODE}"
    return 1
  fi
  [ -n "${KS_BACKUP}" ] || return 0
  ks_cli_hint "--backup and --no-backup do not apply to ${KS_MODE}"
  return 1
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

ks_args_compress_env() {
  [ -n "${KS_FORMAT}" ] || ks_args_format KIRISUTE_FORMAT "${KIRISUTE_FORMAT:-cso2}" || return 1
  [ -n "${KS_BLOCK}" ] || ks_args_block KIRISUTE_BLOCK "${KIRISUTE_BLOCK:-8192}" || return 1
  [ -n "${KS_LZ4_COST}" ] || ks_args_cost KIRISUTE_LZ4_COST "${KIRISUTE_LZ4_COST:-0}" || return 1
  [ -n "${KS_BEST}" ] || KS_BEST="$(ks_args_env KIRISUTE_BEST "${KIRISUTE_BEST:-no}")" || return 1
  [ "${KS_LZ4_SET}" = no ] || [ "${KS_FORMAT}" = cso2 ] || {
    ks_cli_hint "--lz4-cost applies only to --format cso2"
    return 1
  }
}

ks_args_settings() {
  if [ -z "${KS_VERIFY}" ]; then
    KS_VERIFY="$(ks_args_env KIRISUTE_VERIFY "${KIRISUTE_VERIFY:-no}")" || return 1
  fi
  if [ -z "${KS_BACKUP}" ]; then
    KS_BACKUP="$(ks_args_env KIRISUTE_BACKUP "${KIRISUTE_BACKUP:-no}")" || return 1
  fi
  [ "${KS_MODE}" != compress ] || ks_args_compress_env
}

ks_args_inputs() {
  ks_ai_mode="$1"
  shift
  KS_ARGS_DONE=no
  ks_ai_skip=no
  for ks_ai_arg in "$@"; do
    if [ "${ks_ai_skip}" = yes ]; then
      ks_ai_skip=no
      continue
    fi
    if [ "${KS_ARGS_DONE}" = no ]; then
      case "${ks_ai_arg}" in
      --) KS_ARGS_DONE=yes ;;
      -?*) ! ks_args_takes_value "${ks_ai_arg}" || ks_ai_skip=yes ;;
      *) ks_walk_input "${ks_ai_mode}" "${ks_ai_arg}" ;;
      esac
      continue
    fi
    ks_walk_input "${ks_ai_mode}" "${ks_ai_arg}"
  done
}
