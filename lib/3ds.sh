#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_3ds_awk_main() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < min) { printf "small 0 0 0 0\t\n"; exit }
      unit = 512
      for (k = 0; k < b[398]; k++) unit *= 2
      status = "ok"
      end = 0
      count = 0
      zero = 1
      for (i = 264; i < 272; i++) if (b[i] != 0) zero = 0
      if (text(256, 4) != "NCSD") status = "magic"
      else {
        for (i = 272; i < 280; i++) if (b[i] != 0) status = "nand"
        if (status == "ok" && zero) status = "media"
        if (status == "ok" && u32(292) == 0) status = "empty"
        for (p = 0; status == "ok" && p < 8; p++) {
          if (u32(292 + 8 * p) == 0) continue
          if (u32(288 + 8 * p) < end) status = "overlap"
          end = u32(288 + 8 * p) + u32(292 + 8 * p)
          count++
        }
        if (status == "ok" && end > u32(260)) status = "size"
      }
      printf "%s %d %d %d %d\t%s\n", status, unit, end, u32(288), count, hex(264, 8)
    }'
}

ks_3ds_fields() {
  if [ -z "${KS_3DS_AWK}" ]; then
    ks_3f_functions="$(ks_rom_awk_functions)"
    ks_3f_main="$(ks_3ds_awk_main)"
    KS_3DS_AWK="${ks_3f_functions}${ks_3f_main}"
  fi
  ks_rom_bytes "$1" 0 "${KS_CTR_HEADER}" | awk -v min="${KS_CTR_HEADER}" "${KS_3DS_AWK}"
}

ks_3ds_product() {
  [ $(($2 + KS_CTR_PRODUCT_AT + 16)) -le "${KS_ROM_SIZE}" ] || return 0
  ks_rom_bytes "$1" $(($2 + KS_CTR_PRODUCT_AT)) 16 | awk '
    { for (i = 1; i <= NF; i++) if ($i >= 32 && $i < 127) s = s sprintf("%c", $i) }
    END { print s }'
}

ks_3ds_read() {
  ks_3r_fields="$(ks_3ds_fields "$1")"
  ks_3r_head="${ks_3r_fields%%"${KS_TAB}"*}"
  KS_3DS_MEDIA="${ks_3r_fields#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_3r_head%% *}"
  ks_3r_head="${ks_3r_head#* }"
  KS_3DS_UNIT="${ks_3r_head%% *}"
  ks_3r_head="${ks_3r_head#* }"
  KS_3DS_END="${ks_3r_head%% *}"
  ks_3r_head="${ks_3r_head#* }"
  ks_3r_first="${ks_3r_head%% *}"
  KS_3DS_PARTS="${ks_3r_head#* }"
  KS_ROM_TITLE=""
  KS_ROM_CODE=""
  [ "${KS_ROM_STATUS}" = ok ] || return 0
  KS_ROM_CODE="$(ks_3ds_product "$1" $((ks_3r_first * KS_3DS_UNIT)))"
}

ks_3ds_reason() {
  case "${KS_ROM_STATUS}" in
  small) KS_REASON="is too small to hold a 3DS header" ;;
  magic) KS_REASON="is not a 3DS cartridge image" ;;
  nand) KS_REASON="is a 3DS NAND image, not a cartridge image" ;;
  media) KS_REASON="has no media ID and is not a 3DS cartridge image" ;;
  empty) KS_REASON="has no first partition" ;;
  overlap) KS_REASON="has partitions that overlap" ;;
  size) KS_REASON="declares partitions past its own image size" ;;
  *) KS_REASON="" ;;
  esac
}

ks_3ds_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET=$((KS_3DS_END * KS_3DS_UNIT))
}

ks_3ds_keeps() {
  :
}

ks_3ds_info() {
  printf 'ID:     %s\nParts:  %s\n' "${KS_3DS_MEDIA}" "${KS_3DS_PARTS}"
}

ks_3ds_json() {
  printf ',"media_id":"%s","partitions":%s' "${KS_3DS_MEDIA}" "${KS_3DS_PARTS}"
}
