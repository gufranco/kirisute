#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_rom_system() {
  case "$1" in
  *.[nN][dD][sS]) KS_SYSTEM=nds ;;
  *.[gG][bB][aA]) KS_SYSTEM=gba ;;
  *.3[dD][sS] | *.[cC][cC][iI]) KS_SYSTEM=3ds ;;
  *.[cC][xX][iI]) KS_SYSTEM=cxi ;;
  *.[iI][sS][oO]) KS_SYSTEM=psp ;;
  *) return 1 ;;
  esac
}

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
    function crcinit(    i, c, k) {
      for (i = 0; i < 256; i++) {
        c = i
        for (k = 0; k < 8; k++) c = (c % 2) ? xor16(int(c / 2), 40961) : int(c / 2)
        table[i] = c
      }
    }
    function crc(start, count,    c, i) {
      c = 65535
      for (i = start; i < start + count; i++) c = xor16(int(c / 256), table[xor16(c, b[i]) % 256])
      return c
    }
    function u16(at) { return b[at] + 256 * b[at + 1] }
    function u32(at) { return b[at] + 256 * b[at + 1] + 65536 * b[at + 2] + 16777216 * b[at + 3] }
    function hex(at, count,    s, i) {
      s = ""
      for (i = at + count - 1; i >= at; i--) s = s sprintf("%02X", b[i])
      return s
    }
    function text(start, count,    s, i) {
      s = ""
      for (i = start; i < start + count; i++) if (b[i] >= 32 && b[i] < 127) s = s sprintf("%c", b[i])
      sub(/ +$/, "", s)
      return s
    }'
}

ks_rom_bytes() {
  od -A n -v -t u1 -j "$2" -N "$3" <"$1"
}

ks_rom_read() {
  ks_rom_system "$1" || KS_SYSTEM="${KS_SYSTEM_DEFAULT}"
  KS_ROM_SIZE="$(ks_file_bytes "$1")"
  "ks_${KS_SYSTEM}_read" "$1"
}

ks_rom_reason() {
  "ks_${KS_SYSTEM}_reason"
}

ks_rom_target() {
  "ks_${KS_SYSTEM}_target" "$1"
}

ks_rom_keeps() {
  "ks_${KS_SYSTEM}_keeps"
}

ks_rom_info() {
  "ks_${KS_SYSTEM}_info"
}

ks_rom_json() {
  "ks_${KS_SYSTEM}_json"
}

ks_rom_dirty() {
  ks_rd_left="$(tail -c "+$(($2 + 1))" <"$1" | tr -d '\000\377' | wc -c | tr -d ' ')"
  [ "${ks_rd_left}" -gt 0 ] || return 1
  tail -c "+$(($2 + 1))" <"$1" | od -A d -v -t u1 | awk -v base="$2" '
    { for (i = 2; i <= NF; i++) if ($i != 0 && $i != 255) { print base + $1 + i - 2; exit } }'
}
