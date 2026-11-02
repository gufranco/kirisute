#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_trim_dir() {
  case "$1" in
  */*) ks_td_dir="${1%/*}" ;;
  *) ks_td_dir=. ;;
  esac
  printf '%s\n' "${ks_td_dir:-/}"
}

ks_trim_mode() {
  stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1" 2>/dev/null
}

ks_cleanup() {
  [ -z "${KS_TMP_CHECK}" ] || rm -f -- "${KS_TMP_CHECK}"
  KS_TMP_CHECK=""
  [ -n "${KS_TMP}" ] || return 0
  rm -f -- "${KS_TMP}"
  KS_TMP=""
}

ks_trim_swap() {
  if [ "${KS_BACKUP}" = no ]; then
    mv -f -- "${KS_TMP}" "$1" && return 0
    ks_error "could not put the trimmed copy in place of $1, so it stays as it was."
    return 1
  fi
  if ! mv -f -- "$1" "$1.bak"; then
    ks_error "could not keep $1 as $1.bak, so it stays as it was."
    return 1
  fi
  mv -f -- "${KS_TMP}" "$1" && return 0
  mv -f -- "$1.bak" "$1"
  ks_error "could not put the trimmed copy in place of $1, so it stays as it was."
  return 1
}

ks_trim_copy() {
  if ! head -c "$2" <"$1" >"${KS_TMP}"; then
    ks_error "could not write the trimmed copy of $1, so it stays as it was."
    return 1
  fi
  ks_tc_written="$(wc -c <"${KS_TMP}" | tr -d ' ')"
  [ "${ks_tc_written}" -eq "$2" ] && return 0
  ks_error "wrote ${ks_tc_written} of $2 bytes of $1, so it stays as it was."
  return 1
}

ks_trim_apply() {
  ks_ta_dir="$(ks_trim_dir "$1")"
  ks_ta_mode="$(ks_trim_mode "$1")" || ks_ta_mode=""
  if ! KS_TMP="$(mktemp "${ks_ta_dir}/.kirisute.XXXXXX")"; then
    KS_TMP=""
    ks_error "could not create a temporary file beside $1, so it stays as it was."
    return 1
  fi
  ks_trim_copy "$1" "$2" || {
    ks_cleanup
    return 1
  }
  if [ -n "${ks_ta_mode}" ] && ! chmod "${ks_ta_mode}" "${KS_TMP}"; then
    ks_error "could not give the trimmed copy of $1 its permissions, so it stays as it was."
    ks_cleanup
    return 1
  fi
  ks_trim_swap "$1" || {
    ks_cleanup
    return 1
  }
  KS_TMP=""
}
