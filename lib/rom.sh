#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_rom_system() {
  case "$1" in
  *.[nN][dD][sS]) KS_SYSTEM=nds ;;
  *) return 1 ;;
  esac
}

ks_rom_read() {
  ks_rom_system "$1" || KS_SYSTEM="${KS_SYSTEM_DEFAULT}"
  KS_ROM_SIZE="$(wc -c <"$1" | tr -d ' ')"
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
