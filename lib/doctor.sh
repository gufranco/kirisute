#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_doctor_row() {
  if ks_ui_out; then
    case "$2" in
    ok) ks_dw_state="@ok:ok" ;;
    *) ks_dw_state="@bad:$2" ;;
    esac
    KS_DOCTOR_ROWS="${KS_DOCTOR_ROWS}$1	${ks_dw_state}	$3
"
    return 0
  fi
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
}

ks_doctor_report() {
  if ! ks_ui_out; then
    return 0
  fi
  printf 'Tool\tState\tDetail\n%s' "${KS_DOCTOR_ROWS}" | ks_ui_table
  if [ "$1" -ne 0 ]; then
    ks_ui_log ERROR "a required tool is missing. install it and run kirisute doctor again."
    return 0
  fi
  ks_ui_done "Ready. Every tool kirisute needs is here."
}

ks_doctor_gum() {
  ks_dg_found="$(command -v gum 2>/dev/null || true)"
  if [ -z "${ks_dg_found}" ]; then
    ks_doctor_row gum missing "install with: brew install gum, or see https://github.com/charmbracelet/gum"
    return 1
  fi
  ks_dg_raw="$(gum --version 2>/dev/null || true)"
  ks_dg_version="$(ks_flavor_version "${ks_dg_raw}")"
  ks_doctor_row gum ok "${ks_dg_found}${ks_dg_version:+, ${ks_dg_version}}"
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

ks_doctor_maxcso() {
  ks_dm_found="$(command -v maxcso 2>/dev/null || true)"
  if [ -z "${ks_dm_found}" ]; then
    ks_doctor_row maxcso missing "required, brew install gufranco/tap/maxcso"
    return 1
  fi
  ks_dm_text="$(maxcso --version 2>&1 </dev/null)" || true
  ks_dm_version="$(printf '%s\n' "${ks_dm_text}" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^v[0-9]/) { print substr($i, 2); exit } }')"
  ks_doctor_row maxcso ok "${ks_dm_found}${ks_dm_version:+, ${ks_dm_version}}"
}

ks_doctor() {
  ks_dr_status=0
  ks_doctor_gum || ks_dr_status=1
  for ks_dr_tool in awk od head tail tr wc mktemp mv stat chmod rm cmp; do
    ks_doctor_tool "${ks_dr_tool}" || ks_dr_status=1
  done
  ks_doctor_maxcso || ks_dr_status=1
  ks_doctor_report "${ks_dr_status}"
  return "${ks_dr_status}"
}
