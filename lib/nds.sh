#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_nds_awk_functions() {
  printf '%s\n' '
    function xor16(a, b,    r, bit, i) {
      r = 0; bit = 1
      for (i = 0; i < 16; i++) {
        if ((int(a / bit) % 2) != (int(b / bit) % 2)) r += bit
        bit *= 2
      }
      return r
    }
    function crc(start, count,    c, i) {
      c = 65535
      for (i = start; i < start + count; i++) c = xor16(int(c / 256), table[xor16(c, b[i]) % 256])
      return c
    }
    function u32(at) { return b[at] + 256 * b[at + 1] + 65536 * b[at + 2] + 16777216 * b[at + 3] }
    function text(start, count,    s, i) {
      s = ""
      for (i = start; i < start + count; i++) if (b[i] >= 32 && b[i] < 127) s = s sprintf("%c", b[i])
      return s
    }'
}

ks_nds_awk_main() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < min) { printf "small 0 0 0\t\t\n"; exit }
      for (i = 0; i < 256; i++) {
        c = i
        for (k = 0; k < 8; k++) c = (c % 2) ? xor16(int(c / 2), 40961) : int(c / 2)
        table[i] = c
      }
      status = "ok"
      if (crc(192, 156) != logo) status = "logo"
      else if (crc(0, 350) != b[350] + 256 * b[351]) status = "crc"
      printf "%s %d %d %d\t%s\t%s\n", status, b[18], u32(128), u32(528), text(0, 12), text(12, 4)
    }'
}

ks_nds_fields() {
  if [ -z "${KS_NDS_AWK}" ]; then
    ks_nf_functions="$(ks_nds_awk_functions)"
    ks_nf_main="$(ks_nds_awk_main)"
    KS_NDS_AWK="${ks_nf_functions}${ks_nf_main}"
  fi
  od -A n -v -t u1 -N "${KS_NDS_HEADER_READ}" <"$1" |
    awk -v min="${KS_NDS_HEADER_MIN}" -v logo="${KS_NDS_LOGO_CRC}" "${KS_NDS_AWK}"
}

ks_nds_read() {
  ks_nr_fields="$(ks_nds_fields "$1")"
  ks_nr_head="${ks_nr_fields%%"${KS_TAB}"*}"
  ks_nr_rest="${ks_nr_fields#*"${KS_TAB}"}"
  KS_ROM_TITLE="${ks_nr_rest%%"${KS_TAB}"*}"
  KS_ROM_CODE="${ks_nr_rest#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_nr_head%% *}"
  ks_nr_head="${ks_nr_head#* }"
  KS_NDS_UNIT="${ks_nr_head%% *}"
  ks_nr_head="${ks_nr_head#* }"
  KS_NDS_NTR="${ks_nr_head%% *}"
  KS_NDS_TWL="${ks_nr_head#* }"
}

ks_nds_reason() {
  case "${KS_ROM_STATUS}" in
  small) KS_REASON="is too small to hold a DS header" ;;
  logo) KS_REASON="has a bad logo checksum and is not a DS ROM" ;;
  crc) KS_REASON="has a bad header checksum" ;;
  *) KS_REASON="" ;;
  esac
}

ks_nds_magic() {
  od -A n -t x1 -j "$2" -N 2 <"$1" | tr -d ' \n'
}

ks_nds_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET="${KS_NDS_NTR}"
  if [ "${KS_NDS_UNIT}" -ne 0 ]; then
    KS_ROM_KIND=dsi
    KS_ROM_TARGET="${KS_NDS_TWL}"
  elif [ "${KS_NDS_NTR}" -lt "${KS_ROM_SIZE}" ]; then
    ks_nt_magic="$(ks_nds_magic "$1" "${KS_NDS_NTR}")"
    if [ "${ks_nt_magic}" = "${KS_NDS_RSA_MAGIC}" ]; then
      KS_ROM_KIND=rsa
      KS_ROM_TARGET=$((KS_NDS_NTR + KS_NDS_RSA_SIZE))
    fi
  fi
  [ "${KS_ROM_TARGET}" -gt 0 ]
}

ks_nds_keeps() {
  case "${KS_ROM_KIND}" in
  rsa) printf ', keeping its download-play certificate' ;;
  dsi) printf ', keeping its DSi area' ;;
  *) : ;;
  esac
}

ks_nds_kind_label() {
  case "$1" in
  rsa) printf 'yes, download play\n' ;;
  *) printf 'none\n' ;;
  esac
}

ks_nds_unit_label() {
  case "$1" in
  0) printf 'NTR, DS\n' ;;
  2) printf 'NTR and TWL, DSi enhanced\n' ;;
  3) printf 'TWL, DSi only\n' ;;
  *) printf 'unknown\n' ;;
  esac
}

ks_nds_info() {
  ks_ni_unit="$(ks_nds_unit_label "${KS_NDS_UNIT}")"
  ks_ni_cert="$(ks_nds_kind_label "${KS_ROM_KIND}")"
  printf 'Unit:   0x%02x, %s\nCert:   %s\n' "${KS_NDS_UNIT}" "${ks_ni_unit}" "${ks_ni_cert}"
}

ks_nds_json() {
  printf ',"unit_code":%s' "${KS_NDS_UNIT}"
}
