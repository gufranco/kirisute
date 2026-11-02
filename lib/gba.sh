#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_gba_awk_main() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < min) { printf "small 0\t\t\t\n"; exit }
      crcinit()
      sum = 25
      for (i = 160; i < 189; i++) sum += b[i]
      check = (256 - sum % 256) % 256
      status = "ok"
      if (crc(4, 156) != logo) status = "logo"
      else if (b[178] != 150) status = "fixed"
      else if (b[189] != check) status = "crc"
      printf "%s %d\t%s\t%s\t%s\n", status, b[188], text(160, 12), text(172, 4), text(176, 2)
    }'
}

ks_gba_fields() {
  if [ -z "${KS_GBA_AWK}" ]; then
    ks_gf_functions="$(ks_rom_awk_functions)"
    ks_gf_main="$(ks_gba_awk_main)"
    KS_GBA_AWK="${ks_gf_functions}${ks_gf_main}"
  fi
  ks_rom_bytes "$1" 0 "${KS_GBA_HEADER_READ}" |
    awk -v min="${KS_GBA_HEADER_READ}" -v logo="${KS_LOGO_CRC}" "${KS_GBA_AWK}"
}

ks_gba_read() {
  ks_gr_fields="$(ks_gba_fields "$1")"
  ks_gr_head="${ks_gr_fields%%"${KS_TAB}"*}"
  ks_gr_rest="${ks_gr_fields#*"${KS_TAB}"}"
  KS_ROM_TITLE="${ks_gr_rest%%"${KS_TAB}"*}"
  ks_gr_rest="${ks_gr_rest#*"${KS_TAB}"}"
  KS_ROM_CODE="${ks_gr_rest%%"${KS_TAB}"*}"
  KS_GBA_MAKER="${ks_gr_rest#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_gr_head%% *}"
  KS_GBA_VERSION="${ks_gr_head#* }"
}

ks_gba_reason() {
  case "${KS_ROM_STATUS}" in
  small) KS_REASON="is too small to hold a Game Boy Advance header" ;;
  logo) KS_REASON="has a bad logo checksum and is not a Game Boy Advance ROM" ;;
  fixed) KS_REASON="lacks the fixed header byte of a Game Boy Advance ROM" ;;
  crc) KS_REASON="has a bad header checksum" ;;
  *) KS_REASON="" ;;
  esac
}

ks_gba_block() {
  tail -c "+$(($2 + 1))" <"$1" | head -c "$3"
}

ks_gba_data_end() {
  ks_ge_from="${KS_ROM_SIZE}"
  ks_ge_take=0
  ks_ge_data=0
  while [ "${ks_ge_data}" -eq 0 ] && [ "${ks_ge_from}" -gt 0 ]; do
    ks_ge_take="${KS_GBA_SCAN_BLOCK}"
    [ "${ks_ge_take}" -le "${ks_ge_from}" ] || ks_ge_take="${ks_ge_from}"
    ks_ge_from=$((ks_ge_from - ks_ge_take))
    ks_ge_data="$(ks_gba_block "$1" "${ks_ge_from}" "${ks_ge_take}" | tr -d "$2" | wc -c | tr -d ' ')"
  done
  ks_gba_block "$1" "${ks_ge_from}" "${ks_ge_take}" | od -A d -v -t u1 | awk -v base="${ks_ge_from}" -v pad="$3" '
    { for (i = 2; i <= NF; i++) if ($i != pad) last = base + $1 + i - 1 }
    END { print last + 0 }'
}

ks_gba_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET="${KS_ROM_SIZE}"
  ks_gt_pad="$(tail -c 1 <"$1" | od -A n -t u1 | tr -d ' \n')"
  case "${ks_gt_pad}" in
  0) ks_gt_char='\000' ;;
  255) ks_gt_char='\377' ;;
  *) return 0 ;;
  esac
  ks_gt_end="$(ks_gba_data_end "$1" "${ks_gt_char}" "${ks_gt_pad}")"
  ks_gt_end=$(((ks_gt_end + 3) / 4 * 4))
  [ $((KS_ROM_SIZE - ks_gt_end)) -lt "${KS_GBA_MIN_CUT}" ] || KS_ROM_TARGET="${ks_gt_end}"
}

ks_gba_keeps() {
  :
}

ks_gba_info() {
  printf 'Maker:  %s\nRev:    %s\n' "${KS_GBA_MAKER}" "${KS_GBA_VERSION}"
}

ks_gba_json() {
  ks_gj_maker="$(ks_json_string "${KS_GBA_MAKER}")"
  printf ',"maker_code":%s,"version":%s' "${ks_gj_maker}" "${KS_GBA_VERSION}"
}
