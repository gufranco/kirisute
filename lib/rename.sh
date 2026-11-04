#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_rename_clean() {
  printf '%s' "$1" | tr '/:' '--' | tr -d '\000-\037\177' | tr -s ' '
}

ks_rename_base() {
  ks_rb_title="$(ks_rename_clean "${KS_ROM_TITLE}")"
  ks_rb_code="$(ks_rename_clean "${KS_ROM_CODE}")"
  if [ -n "${ks_rb_title}" ] && [ -n "${ks_rb_code}" ]; then
    printf '%s (%s)\n' "${ks_rb_title}" "${ks_rb_code}"
  else
    printf '%s\n' "${ks_rb_title}${ks_rb_code}"
  fi
}

ks_rename_target() {
  ks_rt_file="${1##*/}"
  ks_rt_ext=""
  case "${ks_rt_file}" in
  ?*.*) ks_rt_ext=".$(printf '%s' "${ks_rt_file##*.}" | tr '[:upper:]' '[:lower:]')" ;;
  *) : ;;
  esac
  case "$1" in
  */*) printf '%s/%s%s\n' "${1%/*}" "$2" "${ks_rt_ext}" ;;
  *) printf '%s%s\n' "$2" "${ks_rt_ext}" ;;
  esac
}

ks_rename_move() {
  if [ "$1" -ef "$2" ]; then
    mv -- "$1" "$2.kirisute" && mv -- "$2.kirisute" "$2"
    return
  fi
  mv -- "$1" "$2"
}

ks_rename_free() {
  [ "$1" -ef "$2" ] && return 0
  [ ! -e "$2" ] && [ ! -L "$2" ]
}

ks_rename_apply() {
  KS_NEW_NAME="$2"
  if ! ks_rename_free "$1" "$2"; then
    ks_skip "$1" "cannot take the name ${2##*/}, which another file has"
    return 0
  fi
  if [ "${KS_DRY_RUN}" = no ] && ! ks_rename_move "$1" "$2"; then
    KS_FAILED=$((KS_FAILED + 1))
    ks_record failed "could not rename" "$1"
    return 0
  fi
  KS_DONE=$((KS_DONE + 1))
  ks_ra_verb=Renamed
  ks_ra_status=renamed
  if [ "${KS_DRY_RUN}" = yes ]; then
    ks_ra_verb="Would rename"
    ks_ra_status=would-rename
  fi
  ks_record "${ks_ra_status}" "" "$1"
  [ "${KS_JSON}" = yes ] || ks_say "${ks_ra_verb} $1 to ${2##*/}."
}

ks_rename_process() {
  ks_rom_reason
  if [ -n "${KS_REASON}" ]; then
    ks_skip "$1" "${KS_REASON}"
    return 0
  fi
  ks_rp_base="$(ks_rename_base)"
  if [ -z "${ks_rp_base}" ]; then
    ks_skip "$1" "has no title or code in its header to name it by"
    return 0
  fi
  ks_rp_new="$(ks_rename_target "$1" "${ks_rp_base}")"
  if [ "${ks_rp_new}" = "$1" ]; then
    KS_ALREADY=$((KS_ALREADY + 1))
    ks_record already "" "$1"
    [ "${KS_JSON}" = yes ] || ks_say "$1 is already named after its header."
    return 0
  fi
  ks_rename_apply "$1" "${ks_rp_new}"
}

ks_rename_plan() {
  printf 'Plan:   rename each ROM after the title and code in its header\n'
  [ "${KS_DRY_RUN}" = no ] || printf '        dry run: list each new name and change nothing\n'
}

ks_rename_report() {
  ks_rr_count="$(ks_report_count "${KS_DONE}")"
  if [ "${KS_FOUND}" -eq 0 ]; then
    printf 'No ROM to rename.\n'
  elif [ "${KS_DRY_RUN}" = yes ]; then
    printf 'Dry run: %s would be renamed. Nothing was changed.\n' "${ks_rr_count}"
  elif [ "${KS_DONE}" -gt 0 ]; then
    printf 'Renamed %s.\n' "${ks_rr_count}"
  elif [ "${KS_ALREADY}" -eq "${KS_FOUND}" ]; then
    printf 'Nothing to rename: every ROM is already named after its header.\n'
  else
    printf 'Nothing was renamed.\n'
  fi
}
