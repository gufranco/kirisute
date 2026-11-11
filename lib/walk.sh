#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_walk_refuse() {
  [ "$1" = tally ] || return 0
  ks_error "$2"
  KS_FAILED=$((KS_FAILED + 1))
}

ks_walk_input() {
  if [ -L "$2" ]; then
    ks_walk_refuse "$1" "$2 is a symbolic link, so it stays as it is. give the file it points to."
  elif [ -d "$2" ]; then
    ks_walk_dir "$1" 0 "$2"
  elif [ -f "$2" ]; then
    ks_visit "$1" "$2"
  elif [ -e "$2" ]; then
    ks_walk_refuse "$1" "$2 is not a regular file, so it stays as it is."
  else
    ks_walk_refuse "$1" "no such file or folder: $2"
  fi
}

ks_walk_entry() {
  [ -L "$3" ] && return 0
  if [ -d "$3" ]; then
    [ "${KS_RECURSIVE}" = no ] || ks_walk_dir "$1" "$(($2 + 1))" "$3"
    return 0
  fi
  ks_rom_system "$3" || return 0
  [ "${KS_MODE}" != compress ] || [ "${KS_SYSTEM}" = psp ] || return 0
  [ ! -f "$3" ] || ks_visit "$1" "$3"
}

ks_walk_deep() {
  [ "$1" = tally ] || return 0
  ks_warning "$2 is more than ${KS_DEPTH_MAX} folders deep, so kirisute does not look inside it."
  KS_SKIPPED=$((KS_SKIPPED + 1))
}

ks_walk_dir() {
  if [ "$2" -ge "${KS_DEPTH_MAX}" ]; then
    ks_walk_deep "$1" "$3"
    return 0
  fi
  case "$3" in
  */) ks_wd_dir="$3" ;;
  *) ks_wd_dir="$3/" ;;
  esac
  set -- "$1" "$2" "${ks_wd_dir}"*
  while [ "$#" -gt 2 ]; do
    ks_walk_entry "$1" "$2" "$3"
    ks_wd_mode="$1"
    ks_wd_depth="$2"
    shift 3
    set -- "${ks_wd_mode}" "${ks_wd_depth}" "$@"
  done
}

ks_visit() {
  if [ "$1" = act ]; then
    ks_process "$2"
    return 0
  fi
  ks_vi_size="$(ks_file_bytes "$2")"
  KS_FOUND=$((KS_FOUND + 1))
  KS_BYTES=$((KS_BYTES + ks_vi_size))
}
