#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_cxi_awk_main() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < min) { printf "small 0\t\t\n"; exit }
      status = "ok"
      if (text(256, 4) != "NCCH") status = "magic"
      printf "%s %d\t%s\t%s\n", status, u32(260), text(336, 16), hex(280, 8)
    }'
}

ks_cxi_fields() {
  if [ -z "${KS_CXI_AWK}" ]; then
    ks_cf_functions="$(ks_rom_awk_functions)"
    ks_cf_main="$(ks_cxi_awk_main)"
    KS_CXI_AWK="${ks_cf_functions}${ks_cf_main}"
  fi
  ks_rom_bytes "$1" 0 "${KS_CTR_HEADER}" | awk -v min="${KS_CTR_HEADER}" "${KS_CXI_AWK}"
}

ks_cxi_read() {
  ks_cr_fields="$(ks_cxi_fields "$1")"
  ks_cr_head="${ks_cr_fields%%"${KS_TAB}"*}"
  ks_cr_rest="${ks_cr_fields#*"${KS_TAB}"}"
  KS_ROM_TITLE=""
  KS_ROM_CODE="${ks_cr_rest%%"${KS_TAB}"*}"
  KS_CXI_PROGRAM="${ks_cr_rest#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_cr_head%% *}"
  KS_CXI_UNITS="${ks_cr_head#* }"
}

ks_cxi_reason() {
  case "${KS_ROM_STATUS}" in
  small) KS_REASON="is too small to hold a 3DS executable header" ;;
  magic) KS_REASON="is not a 3DS executable" ;;
  *) KS_REASON="" ;;
  esac
}

ks_cxi_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET=$((KS_CXI_UNITS * KS_CTR_UNIT))
  [ "${KS_ROM_TARGET}" -gt 0 ]
}

ks_cxi_keeps() {
  :
}

ks_cxi_info() {
  printf 'ID:     %s\n' "${KS_CXI_PROGRAM}"
}

ks_cxi_json() {
  printf ',"program_id":"%s"' "${KS_CXI_PROGRAM}"
}
