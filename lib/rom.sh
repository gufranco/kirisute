#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_rom_awk_functions() {
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

ks_rom_awk_main() {
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

ks_rom_fields() {
  if [ -z "${KS_ROM_AWK}" ]; then
    ks_rf_functions="$(ks_rom_awk_functions)"
    ks_rf_main="$(ks_rom_awk_main)"
    KS_ROM_AWK="${ks_rf_functions}${ks_rf_main}"
  fi
  od -A n -v -t u1 -N "${KS_HEADER_READ}" <"$1" |
    awk -v min="${KS_HEADER_MIN}" -v logo="${KS_LOGO_CRC}" "${KS_ROM_AWK}"
}

ks_rom_read() {
  KS_ROM_SIZE="$(wc -c <"$1" | tr -d ' ')"
  ks_rr_fields="$(ks_rom_fields "$1")"
  ks_rr_head="${ks_rr_fields%%"${KS_TAB}"*}"
  ks_rr_rest="${ks_rr_fields#*"${KS_TAB}"}"
  KS_ROM_TITLE="${ks_rr_rest%%"${KS_TAB}"*}"
  KS_ROM_CODE="${ks_rr_rest#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_rr_head%% *}"
  ks_rr_head="${ks_rr_head#* }"
  KS_ROM_UNIT="${ks_rr_head%% *}"
  ks_rr_head="${ks_rr_head#* }"
  KS_ROM_NTR="${ks_rr_head%% *}"
  KS_ROM_TWL="${ks_rr_head#* }"
}

ks_rom_magic() {
  od -A n -t x1 -j "$2" -N 2 <"$1" | tr -d ' \n'
}

ks_rom_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET="${KS_ROM_NTR}"
  if [ "${KS_ROM_UNIT}" -ne 0 ]; then
    KS_ROM_KIND=dsi
    KS_ROM_TARGET="${KS_ROM_TWL}"
  elif [ "${KS_ROM_NTR}" -lt "${KS_ROM_SIZE}" ]; then
    ks_rt_magic="$(ks_rom_magic "$1" "${KS_ROM_NTR}")"
    if [ "${ks_rt_magic}" = "${KS_RSA_MAGIC}" ]; then
      KS_ROM_KIND=rsa
      KS_ROM_TARGET=$((KS_ROM_NTR + KS_RSA_SIZE))
    fi
  fi
  [ "${KS_ROM_TARGET}" -gt 0 ]
}

ks_rom_dirty() {
  ks_rd_left="$(tail -c "+$(($2 + 1))" <"$1" | tr -d '\000\377' | wc -c | tr -d ' ')"
  [ "${ks_rd_left}" -gt 0 ] || return 1
  tail -c "+$(($2 + 1))" <"$1" | od -A d -v -t u1 | awk -v base="$2" '
    { for (i = 2; i <= NF; i++) if ($i != 0 && $i != 255) { print base + $1 + i - 2; exit } }'
}

ks_rom_kind_label() {
  case "$1" in
  rsa) printf 'yes, download play\n' ;;
  *) printf 'none\n' ;;
  esac
}

ks_rom_unit_label() {
  case "$1" in
  0) printf 'NTR, DS\n' ;;
  2) printf 'NTR and TWL, DSi enhanced\n' ;;
  3) printf 'TWL, DSi only\n' ;;
  *) printf 'unknown\n' ;;
  esac
}
