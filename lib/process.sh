#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_record() {
  [ "${KS_JSON}" = yes ] || return 0
  ks_rc_file="$(ks_json_string "$3")"
  ks_rc_item="{\"file\":${ks_rc_file},\"status\":\"$1\",\"size\":${KS_ROM_SIZE}"
  if [ -n "${KS_ROM_KIND}" ]; then
    ks_rc_item="${ks_rc_item},\"kind\":\"${KS_ROM_KIND}\",\"trimmed_size\":${KS_ROM_TARGET}"
  fi
  if [ -n "$2" ]; then
    ks_rc_reason="$(ks_json_string "$2")"
    ks_rc_item="${ks_rc_item},\"reason\":${ks_rc_reason}"
  fi
  if [ -n "${KS_NEW_NAME}" ]; then
    ks_rc_name="$(ks_json_string "${KS_NEW_NAME}")"
    ks_rc_item="${ks_rc_item},\"new_name\":${ks_rc_name}"
  fi
  if [ "$1" = info ]; then
    ks_rc_title="$(ks_json_string "${KS_ROM_TITLE}")"
    ks_rc_code="$(ks_json_string "${KS_ROM_CODE}")"
    ks_rc_system="$(ks_rom_json)"
    ks_rc_item="${ks_rc_item},\"title\":${ks_rc_title},\"game_code\":${ks_rc_code}${ks_rc_system}"
  fi
  KS_RESULTS="${KS_RESULTS}${KS_RESULTS:+,}${ks_rc_item}}"
}

ks_skip() {
  ks_warning "$1 $2, so it stays as it is."
  KS_SKIPPED=$((KS_SKIPPED + 1))
  ks_record skipped "$2" "$1"
}

ks_check() {
  ks_rom_reason
  [ -z "${KS_REASON}" ] || return 1
  if ! ks_rom_target "$1"; then
    KS_REASON="declares a ROM size of 0"
    return 1
  fi
  [ "${KS_ROM_TARGET}" -le "${KS_ROM_SIZE}" ] && return 0
  KS_REASON="is shorter than its header says"
  KS_ROM_KIND=""
  return 1
}

ks_ready() {
  if [ "${KS_VERIFY}" = yes ] || [ "${KS_ROM_STRICT}" = yes ]; then
    ks_re_offset="$(ks_rom_dirty "$1" "${KS_ROM_TARGET}")" || ks_re_offset=""
    if [ -n "${ks_re_offset}" ]; then
      KS_REASON="holds data at byte ${ks_re_offset}, past its real size"
      return 1
    fi
  fi
  [ "${KS_BACKUP}" = yes ] && [ "${KS_DRY_RUN}" = no ] || return 0
  [ -e "$1.bak" ] || [ -L "$1.bak" ] || return 0
  KS_REASON="has a $1.bak already"
  return 1
}

ks_cut() {
  ks_cu_before="$(ks_human "${KS_ROM_SIZE}")"
  ks_cu_after="$(ks_human "${KS_ROM_TARGET}")"
  ks_cu_keeps="$(ks_rom_keeps)"
  if [ "${KS_DRY_RUN}" = no ] && ! ks_trim_apply "$1" "${KS_ROM_TARGET}"; then
    KS_FAILED=$((KS_FAILED + 1))
    ks_record failed "could not trim" "$1"
    return 0
  fi
  KS_DONE=$((KS_DONE + 1))
  KS_SAVED=$((KS_SAVED + KS_ROM_SIZE - KS_ROM_TARGET))
  ks_cu_status=trimmed
  ks_cu_verb=Trimmed
  if [ "${KS_DRY_RUN}" = yes ]; then
    ks_cu_status=would-trim
    ks_cu_verb="Would trim"
  fi
  ks_record "${ks_cu_status}" "" "$1"
  [ "${KS_JSON}" = yes ] || ks_say 0 "${ks_cu_verb} $1 from ${ks_cu_before} to ${ks_cu_after}${ks_cu_keeps}."
}

ks_process() {
  KS_ROM_KIND=""
  KS_ROM_TARGET=0
  KS_NEW_NAME=""
  KS_ROM_STRICT=no
  ks_rom_read "$1"
  if [ "${KS_RENAME}" = yes ]; then
    ks_rename_process "$1"
    return 0
  fi
  if ! ks_check "$1"; then
    ks_skip "$1" "${KS_REASON}"
    return 0
  fi
  if [ "${KS_INFO}" = yes ]; then
    ks_show_info "$1"
    return 0
  fi
  if [ "${KS_ROM_TARGET}" -eq "${KS_ROM_SIZE}" ]; then
    KS_ALREADY=$((KS_ALREADY + 1))
    ks_record already "" "$1"
    ks_pr_size="$(ks_human "${KS_ROM_SIZE}")"
    [ "${KS_JSON}" = yes ] || ks_say 0 "$1 is already at its real size, ${ks_pr_size}."
    return 0
  fi
  if ! ks_ready "$1"; then
    ks_skip "$1" "${KS_REASON}"
    return 0
  fi
  ks_cut "$1"
}

ks_show_info() {
  KS_READ=$((KS_READ + 1))
  ks_record info "" "$1"
  [ "${KS_JSON}" = no ] || return 0
  ks_si_size="$(ks_human "${KS_ROM_SIZE}")"
  ks_si_trim="$(ks_human "${KS_ROM_TARGET}")"
  ks_si_pad="$(ks_human "$((KS_ROM_SIZE - KS_ROM_TARGET))")"
  ks_say 8 "File:   $1, ${ks_si_size}"
  [ -z "${KS_ROM_TITLE}" ] || printf 'Title:  %s\n' "${KS_ROM_TITLE}"
  [ -z "${KS_ROM_CODE}" ] || printf 'Code:   %s\n' "${KS_ROM_CODE}"
  ks_rom_info
  printf 'Trim:   %s, %s of padding\n\n' "${ks_si_trim}" "${ks_si_pad}"
}
