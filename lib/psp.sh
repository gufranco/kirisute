#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_psp_awk_volume() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < min) { printf "small 0 0 0 0\t\n"; exit }
      status = "ok"
      if (b[0] != 1 || text(1, 5) != "CD001" || u16(128) == 0) status = "iso"
      sysid = text(8, 32)
      umd = (sysid == "PSP GAME" || sysid == "\"PSP GAME\"" || sysid == "UMD VIDEO" || sysid == "UMD AUDIO")
      printf "%s %d %d %d %d %d\t%s\n", status, umd, u16(128), u32(80), u32(158), u32(166), text(40, 32)
    }'
}

ks_psp_awk_find() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      p = 0
      while (p < n) {
        if (b[p] == 0) { p = (int(p / block) + 1) * block; continue }
        isdir = (int(b[p + 25] / 2) % 2 == 1)
        if (isdir == want && text(p + 33, b[p + 32]) == name) { printf "%d %d\n", u32(p + 2), u32(p + 10); exit }
        p += b[p]
      }
    }'
}

ks_psp_awk_sfo() {
  # shellcheck disable=SC2016
  printf '%s\n' '
    function cstr(at,    s) {
      s = ""
      while (at < n && b[at] != 0) s = s sprintf("%c", b[at++])
      return s
    }
    { for (i = 1; i <= NF; i++) b[n++] = $i + 0 }
    END {
      if (n < 20 || b[0] != 0 || text(1, 3) != "PSF") exit
      keys = u32(8); data = u32(12)
      for (e = 0; e < u32(16) && e < limit; e++) {
        at = 20 + 16 * e
        key = cstr(keys + u16(at))
        if (key == "TITLE") title = cstr(data + u32(at + 12))
        if (key == "DISC_ID") id = cstr(data + u32(at + 12))
      }
      printf "%s\t%s\n", title, id
    }'
}

ks_psp_program() {
  ks_pp_functions="$(ks_rom_awk_functions)"
  ks_pp_main="$("ks_psp_awk_$1")"
  printf '%s%s' "${ks_pp_functions}" "${ks_pp_main}"
}

ks_psp_extent() {
  ks_pe_take="${2#* }"
  [ "${ks_pe_take}" -le "${KS_PSP_READ_MAX}" ] || ks_pe_take="${KS_PSP_READ_MAX}"
  ks_rom_bytes "$1" $((${2%% *} * KS_PSP_BLOCK)) "${ks_pe_take}"
}

ks_psp_find() {
  [ -n "${KS_PSP_FIND_AWK}" ] || KS_PSP_FIND_AWK="$(ks_psp_program find)"
  ks_psp_extent "$1" "$2" |
    awk -v block="${KS_PSP_BLOCK}" -v name="$3" -v want="$4" "${KS_PSP_FIND_AWK}"
}

ks_psp_meta() {
  [ -n "${KS_PSP_SFO_AWK}" ] || KS_PSP_SFO_AWK="$(ks_psp_program sfo)"
  ks_psp_extent "$1" "$2" | awk -v limit="${KS_PSP_SFO_ENTRIES}" "${KS_PSP_SFO_AWK}"
}

ks_psp_volume() {
  [ -n "${KS_PSP_VOLUME_AWK}" ] || KS_PSP_VOLUME_AWK="$(ks_psp_program volume)"
  ks_rom_bytes "$1" "${KS_PSP_DESCRIPTOR_AT}" "${KS_PSP_SECTOR}" |
    awk -v min="${KS_PSP_SECTOR}" "${KS_PSP_VOLUME_AWK}"
}

ks_psp_unknown() {
  KS_ROM_STATUS=psp
  ks_pu_layer="$(ks_psp_find "$1" "$2" "USER_L0.IMG;1" 0)"
  [ -z "${ks_pu_layer}" ] || KS_ROM_STATUS=wrapper
}

ks_psp_read() {
  KS_ROM_TITLE=""
  KS_ROM_CODE=""
  KS_ROM_STRICT=yes
  ks_ps_fields="$(ks_psp_volume "$1")"
  ks_ps_head="${ks_ps_fields%%"${KS_TAB}"*}"
  KS_PSP_VOLUME="${ks_ps_fields#*"${KS_TAB}"}"
  KS_ROM_STATUS="${ks_ps_head%% *}"
  ks_ps_head="${ks_ps_head#* }"
  ks_ps_umd="${ks_ps_head%% *}"
  ks_ps_head="${ks_ps_head#* }"
  KS_PSP_BLOCK="${ks_ps_head%% *}"
  ks_ps_head="${ks_ps_head#* }"
  KS_PSP_SPACE="${ks_ps_head%% *}"
  ks_ps_root="${ks_ps_head#* }"
  [ "${KS_ROM_STATUS}" = ok ] || return 0
  ks_ps_game="$(ks_psp_find "$1" "${ks_ps_root}" PSP_GAME 1)"
  if [ -z "${ks_ps_game}" ]; then
    [ "${ks_ps_umd}" -eq 1 ] || ks_psp_unknown "$1" "${ks_ps_root}"
    return 0
  fi
  ks_ps_sfo="$(ks_psp_find "$1" "${ks_ps_game}" "PARAM.SFO;1" 0)"
  [ -n "${ks_ps_sfo}" ] || return 0
  ks_ps_meta="$(ks_psp_meta "$1" "${ks_ps_sfo}")"
  KS_ROM_TITLE="${ks_ps_meta%%"${KS_TAB}"*}"
  KS_ROM_CODE="${ks_ps_meta#*"${KS_TAB}"}"
}

ks_psp_reason() {
  case "${KS_ROM_STATUS}" in
  small) KS_REASON="is too small to hold an ISO 9660 volume descriptor" ;;
  iso) KS_REASON="is not an ISO 9660 disc image" ;;
  psp) KS_REASON="names no PSP system and has no PSP_GAME folder, so it is not a PSP disc image" ;;
  wrapper) KS_REASON="is a development DVD-R image; join USER_L0.IMG and USER_L1.IMG, layer 0 first, and trim that" ;;
  *) KS_REASON="" ;;
  esac
}

ks_psp_target() {
  KS_ROM_KIND=plain
  KS_ROM_TARGET=$((KS_PSP_SPACE * KS_PSP_BLOCK))
  [ "${KS_ROM_TARGET}" -gt 0 ]
}

ks_psp_keeps() {
  :
}

ks_psp_info() {
  printf 'Volume: %s\n' "${KS_PSP_VOLUME}"
}

ks_psp_json() {
  ks_pj_volume="$(ks_json_string "${KS_PSP_VOLUME}")"
  printf ',"volume_id":%s' "${ks_pj_volume}"
}
