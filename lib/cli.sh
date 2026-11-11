#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_usage() {
  if ks_ui_out; then
    ks_usage_text | ks_ui_markdown | ks_gum format --theme "${KS_UI_HELP}"
    return 0
  fi
  ks_usage_text
}

ks_usage_text() {
  cat <<'USAGE'
kirisute - cut GBA, DS, DSi and 3DS ROMs and PSP ISOs to their real size

usage:
  kirisute                      ask for a ROM file or folder, then trim it
  kirisute [options] <rom>...   trim each ROM file, and the ROM files of each
                                folder given
  kirisute rename [options] <rom>...
                                rename each ROM after the title and code in
                                its header, such as KIRISUTE (KSTE).nds
  kirisute compress [options] <iso>...
                                write a compressed copy of each PSP disc image
                                for ARK-4 and ARK-5, keeping the original
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
  --theme NAME                  colours of the terminal interface, see notes

compress:
  --format cso|cso2|zso         CSO v1, CSO v2 or ZSO (default cso2); CSO v2
                                mixes deflate and faster LZ4, ZSO reads fastest
  --block 2048|4096|8192|16384  block size in bytes (default 8192)
  --lz4-cost N                  let a CSO v2 block use LZ4 when that costs at
                                most N% more space, 0 to 100 (default 0, LZ4
                                only where it is smaller)
  --best                        add one more slow trial, Zopfli for CSO or
                                brute-force LZ4 for ZSO: a bit smaller

environment:
  KIRISUTE_VERIFY               yes or no, the default for --verify, no
  KIRISUTE_BACKUP               yes or no, the default for --backup, yes
  KIRISUTE_FORMAT               the default for --format, cso2
  KIRISUTE_BLOCK                the default for --block, 8192
  KIRISUTE_LZ4_COST             the default for --lz4-cost, 0
  KIRISUTE_BEST                 yes or no, the default for --best, no

notes:
  A folder gives its .gba, .nds, .3ds, .cci, .cxi and .iso files; a file given
  by name is read by its extension, and as a DS ROM when it has none of these.
  Each ROM keeps everything its header declares: a DS ROM its download-play
  certificate when it has one and the DSi area of a DSi ROM, a 3DS cartridge
  image every partition, a 3DS executable its declared size, and a PSP ISO
  the volume its ISO 9660 descriptor declares, cut only when everything past
  it is 00 or FF, since a game can read sectors outside its files. Nothing
  inside a volume is removed, update data and padding files included. A Game
  Boy Advance ROM declares no size, so it is cut after its last byte that is
  not padding, on a 4-byte boundary, when that saves at least 512 bytes. A
  file whose header fails its checks, or declares more than the file holds,
  stays as it is. A trimmed file no longer matches the checksum of an
  untrimmed dump in databases such as Redump or No-Intro.
  Each ROM is written to a temporary file beside it and renamed over it, so an
  interrupted run never leaves half a file. Symbolic links, hidden files and
  hidden folders are left alone. rename takes --dry-run, --recursive and
  --json, keeps the extension in lowercase, and never takes a name another
  file has. compress uses maxcso and writes game.cso or game.zso beside each
  PSP disc image; its defaults give the same bytes as a CSO v2 that boots on
  ARK-4 and ARK-5. It keeps a copy only after it decompresses back to the
  original, which needs free space as large as the image for a moment. DAX
  and JSO are not written: maxcso's DAX lacks the zlib headers ARK expects,
  and no open JSO writer exists. -- ends the options, and a file named help,
  doctor, version, rename or compress is trimmed by giving its path, such as
  ./help.

  On a terminal with gum installed, kirisute draws its prompts, summary and
  results with gum. --theme, else KIRISUTE_THEME, else KODOUGU_THEME picks the
  colours: kodougu, catppuccin-mocha, catppuccin-latte, dracula, nord,
  gruvbox, tokyo-night or mono. KODOUGU_ACCENT=#RRGGBB replaces only the
  accent, and NO_COLOR turns colour off.

examples:
  kirisute --dry-run *.nds *.3ds
  kirisute --backup --verify game.nds
  kirisute --recursive ~/roms
  kirisute rename --dry-run *.gba
  kirisute compress game.iso
  kirisute compress --format zso --recursive ~/roms/psp
USAGE
}

ks_cli_hint() {
  ks_error "$1. run '${KS_PROG} help' for usage."
}

ks_cli_version() {
  ks_cv_platform="$(uname -sr)" || ks_cv_platform="unknown"
  if ks_ui_out; then
    ks_cv_text="$(ks_version)"
    ks_cv_badge="$(ks_ui_badge "${KS_UI_ACCENT}" "${ks_cv_text}")"
    ks_cv_chip="$(ks_ui_chip "platform ${ks_cv_platform}")"
    ks_gum join --horizontal "${ks_cv_badge}" " " "${ks_cv_chip}"
    return 0
  fi
  ks_version
  printf 'platform: %s\n' "${ks_cv_platform}"
}

ks_interactive() {
  [ "${KIRISUTE_INTERACTIVE:-}" = 1 ] && return 0
  [ -t 0 ]
}

ks_prompt() {
  if ks_ui_prompts; then
    ks_pd_answer="$(ks_ui_input "$1" "$2")" || return 1
    printf '%s\n' "${ks_pd_answer:-$2}"
    return 0
  fi
  printf '%s [%s]: ' "$1" "$2" >&2
  ks_pr_answer=""
  IFS= read -r ks_pr_answer || [ -n "${ks_pr_answer}" ] || return 1
  printf '%s\n' "${ks_pr_answer:-$2}"
}
