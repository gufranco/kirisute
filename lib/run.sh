#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_ask() {
  if ! ks_interactive; then
    ks_cli_hint "no ROM file given"
    return 1
  fi
  KS_ASKED="$(ks_prompt "ROM file or folder" .)" || return 1
  case "${KS_ASKED}" in
  \~) KS_ASKED="${HOME}" ;;
  \~/*) KS_ASKED="${HOME}/${KS_ASKED#\~/}" ;;
  *) : ;;
  esac
}

ks_summary() {
  [ "${KS_JSON}" = no ] && [ "${KS_INFO}" = no ] || return 0
  ks_su_roms="$(ks_plural "${KS_FOUND}" ROM)"
  ks_su_size="$(ks_human "${KS_BYTES}")"
  printf '\nFiles:  %s, %s\n' "${ks_su_roms}" "${ks_su_size}"
  printf 'Plan:   cut each ROM to the size its header declares\n'
  [ "${KS_BACKUP}" = no ] || printf '        keep each original as <rom>.bak\n'
  [ "${KS_VERIFY}" = no ] || printf '        trim only a ROM whose padding is nothing but 00 or FF\n'
  [ "${KS_DRY_RUN}" = no ] || printf '        dry run: list each cut and change nothing\n'
  printf '\n'
}

ks_report_json() {
  ks_rj_dry=false
  [ "${KS_DRY_RUN}" = no ] || ks_rj_dry=true
  ks_rj_info=false
  [ "${KS_INFO}" = no ] || ks_rj_info=true
  printf '{"dry_run":%s,"info":%s,"roms":%s,"read":%s,"trimmed":%s,"already":%s,"skipped":%s,"failed":%s,"saved":%s,"files":[%s]}\n' \
    "${ks_rj_dry}" "${ks_rj_info}" "${KS_FOUND}" "${KS_READ}" "${KS_DONE}" "${KS_ALREADY}" "${KS_SKIPPED}" "${KS_FAILED}" "${KS_SAVED}" "${KS_RESULTS}"
}

ks_report_count() {
  ks_rco_total="$(ks_plural "${KS_FOUND}" ROM)"
  if [ "$1" -eq "${KS_FOUND}" ]; then
    printf '%s\n' "${ks_rco_total}"
  else
    printf '%s of %s\n' "$1" "${ks_rco_total}"
  fi
}

ks_report_text() {
  ks_rt_count="$(ks_report_count "${KS_DONE}")"
  ks_rt_read="$(ks_report_count "${KS_READ}")"
  ks_rt_saved="$(ks_human "${KS_SAVED}")"
  if [ "${KS_FOUND}" -eq 0 ]; then
    printf 'No ROM to trim.\n'
  elif [ "${KS_INFO}" = yes ]; then
    printf 'Read %s.\n' "${ks_rt_read}"
  elif [ "${KS_DRY_RUN}" = yes ]; then
    printf 'Dry run: %s would be trimmed, saving %s. Nothing was changed.\n' "${ks_rt_count}" "${ks_rt_saved}"
  elif [ "${KS_DONE}" -gt 0 ]; then
    printf 'Trimmed %s and saved %s.\n' "${ks_rt_count}" "${ks_rt_saved}"
  elif [ "${KS_ALREADY}" -eq "${KS_FOUND}" ]; then
    printf 'Nothing to trim: every ROM is already at its real size.\n'
  else
    printf 'Nothing was trimmed.\n'
  fi
}

ks_report() {
  if [ "${KS_JSON}" = yes ]; then
    ks_report_json
  else
    ks_report_text
  fi
  [ "$((KS_SKIPPED + KS_FAILED))" -eq 0 ]
}

ks_start() {
  ks_args_parse "$@" || return 1
  ks_args_settings || return 1
  if [ "${KS_INPUTS}" -eq 0 ]; then
    ks_ask || return 1
    set -- -- "${KS_ASKED}"
  fi
  trap 'ks_cleanup' EXIT
  trap 'ks_cleanup; exit 130' INT
  trap 'ks_cleanup; exit 143' TERM
  ks_args_inputs tally "$@"
  [ "${KS_FOUND}" -eq 0 ] || ks_summary
  ks_args_inputs act "$@"
  ks_report
}
