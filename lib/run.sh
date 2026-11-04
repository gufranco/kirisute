#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_ask() {
  if ! ks_interactive; then
    ks_cli_hint "no ROM file given"
    return 1
  fi
  if ks_ui_prompts; then
    ks_ui_header
  fi
  KS_ASKED="$(ks_prompt "ROM file or folder" .)" || return 1
  case "${KS_ASKED}" in
  \~) KS_ASKED="${HOME}" ;;
  \~/*) KS_ASKED="${HOME}/${KS_ASKED#\~/}" ;;
  *) : ;;
  esac
}

ks_summary_box() {
  ks_sb_text="$1"
  set --
  while IFS= read -r ks_sb_line; do
    case "${ks_sb_line}" in
    "") continue ;;
    " "*) set -- "$@" "" "${ks_sb_line#"${ks_sb_line%%[! ]*}"}" ;;
    *)
      ks_sb_value="${ks_sb_line#*:}"
      set -- "$@" "${ks_sb_line%%:*}:" "${ks_sb_value#"${ks_sb_value%%[! ]*}"}"
      ;;
    esac
  done <<EOF
${ks_sb_text}
EOF
  ks_ui_summary "$@"
}

ks_summary_confirm() {
  [ "${KS_DRY_RUN}" = no ] && ks_ui_prompts || return 0
  case "${KS_MODE}" in
  compress) ks_sc_question="Compress $(ks_report_count "${KS_FOUND}")?" ;;
  rename) ks_sc_question="Rename $(ks_plural "${KS_FOUND}" ROM)?" ;;
  *) ks_sc_question="Trim $(ks_plural "${KS_FOUND}" ROM)?" ;;
  esac
  if ! ks_ui_confirm "${ks_sc_question}" "Go" "Stop"; then
    ks_error "stopped: nothing was changed."
    return 1
  fi
}

ks_summary() {
  [ "${KS_JSON}" = no ] && [ "${KS_INFO}" = no ] || return 0
  if [ "${KS_SUMMARY_BOXED}" = no ] && ks_ui_out; then
    KS_SUMMARY_BOXED=yes
    ks_su_text="$(ks_summary)"
    KS_SUMMARY_BOXED=no
    ks_summary_box "${ks_su_text}"
    ks_summary_confirm
    return
  fi
  ks_su_noun="$(ks_noun)"
  ks_su_roms="$(ks_plural "${KS_FOUND}" "${ks_su_noun}")"
  ks_su_size="$(ks_human "${KS_BYTES}")"
  printf '\nFiles:  %s, %s\n' "${ks_su_roms}" "${ks_su_size}"
  if [ "${KS_MODE}" != trim ]; then
    "ks_${KS_MODE}_plan"
    printf '\n'
    return 0
  fi
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
  if [ "${KS_MODE}" = rename ]; then
    printf '{"dry_run":%s,"roms":%s,"renamed":%s,"already":%s,"skipped":%s,"failed":%s,"files":[%s]}\n' \
      "${ks_rj_dry}" "${KS_FOUND}" "${KS_DONE}" "${KS_ALREADY}" "${KS_SKIPPED}" "${KS_FAILED}" "${KS_RESULTS}"
    return 0
  fi
  if [ "${KS_MODE}" = compress ]; then
    printf '{"dry_run":%s,"format":"%s","block":%s,"roms":%s,"compressed":%s,"skipped":%s,"failed":%s,"saved":%s,"files":[%s]}\n' \
      "${ks_rj_dry}" "${KS_FORMAT}" "${KS_BLOCK}" "${KS_FOUND}" "${KS_DONE}" "${KS_SKIPPED}" "${KS_FAILED}" "${KS_SAVED}" "${KS_RESULTS}"
    return 0
  fi
  printf '{"dry_run":%s,"info":%s,"roms":%s,"read":%s,"trimmed":%s,"already":%s,"skipped":%s,"failed":%s,"saved":%s,"files":[%s]}\n' \
    "${ks_rj_dry}" "${ks_rj_info}" "${KS_FOUND}" "${KS_READ}" "${KS_DONE}" "${KS_ALREADY}" "${KS_SKIPPED}" "${KS_FAILED}" "${KS_SAVED}" "${KS_RESULTS}"
}

ks_noun() {
  if [ "${KS_MODE}" = compress ]; then
    printf 'disc image\n'
    return 0
  fi
  printf 'ROM\n'
}

ks_report_count() {
  ks_rco_noun="$(ks_noun)"
  ks_rco_total="$(ks_plural "${KS_FOUND}" "${ks_rco_noun}")"
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

ks_report_sentence() {
  if [ "${KS_MODE}" != trim ]; then
    "ks_${KS_MODE}_report"
    return
  fi
  ks_report_text
}

ks_report() {
  if [ "${KS_JSON}" = yes ]; then
    ks_report_json
  elif ks_ui_out; then
    ks_rp_line="$(ks_report_sentence)"
    if [ "$((KS_SKIPPED + KS_FAILED))" -eq 0 ]; then
      ks_ui_done "${ks_rp_line}"
    else
      ks_ui_log WARN "${ks_rp_line}"
    fi
  else
    ks_report_sentence
  fi
  [ "$((KS_SKIPPED + KS_FAILED))" -eq 0 ]
}

ks_start() {
  ks_args_parse "$@" || return 1
  ks_args_command_options || return 1
  ks_args_settings || return 1
  [ "${KS_MODE}" != compress ] || ks_compress_ready || return 1
  if [ "${KS_INPUTS}" -eq 0 ]; then
    ks_ask || return 1
    set -- -- "${KS_ASKED}"
  fi
  trap 'ks_cleanup' EXIT
  trap 'ks_cleanup; exit 130' INT
  trap 'ks_cleanup; exit 143' TERM
  ks_args_inputs tally "$@"
  [ "${KS_FOUND}" -eq 0 ] || ks_summary || return 1
  ks_args_inputs act "$@"
  ks_report
}
