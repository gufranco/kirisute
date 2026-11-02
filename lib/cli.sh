#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_usage() {
  cat <<'USAGE'
kirisute - cut Game Boy Advance, DS and DSi ROM files down to their real size

usage:
  kirisute                      ask for a ROM file or folder, then trim it
  kirisute [options] <rom>...   trim each ROM file, and the ROM files of each
                                folder given
  kirisute doctor               check the tools kirisute needs
  kirisute version              print the version
  kirisute help                 print this page

options:
  --dry-run                     list what would be trimmed and change nothing
  --info                        print each ROM's header and change nothing
  --verify, --no-verify         trim only a ROM whose padding holds nothing
                                but 00 or FF bytes
  --backup, --no-backup         keep each original as <rom>.bak
  --recursive                   look for ROM files in every subfolder too
  --json                        print the result as one JSON object, for
                                scripts

environment:
  KIRISUTE_VERIFY               yes or no, the default for --verify, no
  KIRISUTE_BACKUP               yes or no, the default for --backup, no

notes:
  A folder gives its .nds and .gba files; a file given by name is read by its
  extension, and as a DS ROM when the extension is neither. A DS ROM keeps
  everything its header declares: its download-play certificate when it has
  one, and the DSi area of a DSi-enhanced or DSi-only ROM. A Game Boy Advance
  ROM is cut after its last byte that is not padding, on a 4-byte boundary,
  when that saves at least 512 bytes. A file whose logo or header checksum is
  wrong, or whose header declares more than the file holds, stays as it is.
  Each ROM is written to a temporary file beside it and renamed over it, so an
  interrupted run never leaves half a file. Symbolic links, hidden files and
  hidden folders are left alone. -- ends the options, and a file named help,
  doctor or version is trimmed by giving its path, such as ./help.

examples:
  kirisute --dry-run *.nds *.gba
  kirisute --backup --verify game.nds
  kirisute --recursive ~/roms
USAGE
}

ks_cli_hint() {
  ks_say 0 "${KS_PROG}: $1. run '${KS_PROG} help' for usage." >&2
}

ks_cli_version() {
  ks_version
  ks_cv_platform="$(uname -sr)" || ks_cv_platform="unknown"
  printf 'platform: %s\n' "${ks_cv_platform}"
}

ks_interactive() {
  [ "${KIRISUTE_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

ks_prompt() {
  printf '%s [%s]: ' "$1" "$2" >&2
  ks_pr_answer=""
  IFS= read -r ks_pr_answer || [ -n "${ks_pr_answer}" ] || return 1
  printf '%s\n' "${ks_pr_answer:-$2}"
}
