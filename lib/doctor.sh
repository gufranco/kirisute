#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_doctor_row() {
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
}

ks_flavor_version() {
  printf '%s\n' "$1" | awk '{
    for (i = 1; i <= NF; i++) {
      t = $i
      gsub(/[,;()]/, "", t)
      sub(/^v/, "", t)
      if (t ~ /^[0-9]+(\.[0-9]+)+[a-z0-9]*$/ || t ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) { print t; exit }
    }
  }'
}

ks_tool_line() {
  ks_tl_line="$(printf '%s\n' "$1" | awk '/BusyBox|This is not GNU/ { print; exit }')"
  if [ -z "${ks_tl_line}" ]; then
    ks_tl_line="$(printf '%s\n' "$1" | sed -n '1p')"
  fi
  printf '%s\n' "${ks_tl_line}"
}

ks_tool_flavor() {
  ks_tf_raw="$("$1" --version 2>&1 </dev/null)" || true
  ks_tf_text="$(ks_tool_line "${ks_tf_raw}")"
  ks_tf_version="$(ks_flavor_version "${ks_tf_text}")"
  ks_tf_os="${KIRISUTE_OS:-}"
  [ -n "${ks_tf_os}" ] || ks_tf_os="$(uname -s)"
  case "${ks_tf_text}" in
  *uutils*) ks_tf_name=uutils ;;
  *BusyBox*) ks_tf_name=busybox ;;
  *"This is not GNU"*)
    ks_tf_name=busybox
    ks_tf_version=""
    ;;
  *GNU* | *"(coreutils)"*) ks_tf_name=gnu ;;
  *)
    ks_tf_version=""
    case "$1:${ks_tf_os}" in
    *uutils*:* | */cargo/*:*) ks_tf_name=uutils ;;
    *:Darwin | *:*BSD) ks_tf_name=bsd ;;
    *) ks_tf_name=unknown ;;
    esac
    ;;
  esac
  printf '%s%s\n' "${ks_tf_name}" "${ks_tf_version:+ ${ks_tf_version}}"
}

ks_doctor_tool() {
  ks_dt_found="$(command -v "$1" 2>/dev/null || true)"
  if [ -z "${ks_dt_found}" ]; then
    ks_doctor_row "$1" missing "required, part of coreutils"
    return 1
  fi
  ks_dt_flavor="$(ks_tool_flavor "${ks_dt_found}")"
  ks_doctor_row "$1" ok "${ks_dt_found}, ${ks_dt_flavor}"
}

ks_doctor() {
  ks_dr_status=0
  for ks_dr_tool in awk od head tail tr wc mktemp mv stat chmod rm; do
    ks_doctor_tool "${ks_dr_tool}" || ks_dr_status=1
  done
  return "${ks_dr_status}"
}
