#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

ks_compress_ready() {
  command -v maxcso >/dev/null 2>&1 && return 0
  ks_error "compress needs maxcso: brew install gufranco/tap/maxcso"
  return 1
}

ks_compress_label() {
  case "${KS_FORMAT}" in
  cso) printf 'CSO v1\n' ;;
  cso2) printf 'CSO v2\n' ;;
  *) printf 'ZSO\n' ;;
  esac
}

ks_compress_target() {
  ks_ct_ext=cso
  [ "${KS_FORMAT}" != zso ] || ks_ct_ext=zso
  printf '%s.%s\n' "${1%.*}" "${ks_ct_ext}"
}

ks_compress_path() {
  case "$1" in
  -*) printf './%s\n' "$1" ;;
  *) printf '%s\n' "$1" ;;
  esac
}

ks_compress_run() {
  ks_cr_in="$(ks_compress_path "$1")"
  ks_cr_out="$(ks_compress_path "$2")"
  set -- --quiet --block="${KS_BLOCK}"
  case "${KS_FORMAT}" in
  cso) set -- "$@" --format=cso1 --use-zlib --use-7zdeflate ;;
  cso2) set -- "$@" --format=cso2 --use-zlib --use-7zdeflate --use-lz4 --use-lz4brute --lz4-cost="${KS_LZ4_COST}" ;;
  *) set -- "$@" --format=zso --use-lz4 ;;
  esac
  if [ "${KS_BEST}" = yes ]; then
    case "${KS_FORMAT}" in
    zso) set -- "$@" --use-lz4brute ;;
    *) set -- "$@" --use-zopfli ;;
    esac
  fi
  maxcso "$@" "${ks_cr_in}" -o "${ks_cr_out}" >/dev/null 2>&1
}

ks_compress_check() {
  ks_ck_dir="$(ks_trim_dir "$1")"
  if ! KS_TMP_CHECK="$(mktemp "${ks_ck_dir}/.kirisute.XXXXXX")"; then
    KS_TMP_CHECK=""
    return 1
  fi
  ks_ck_copy="$(ks_compress_path "$2")"
  ks_ck_back="$(ks_compress_path "${KS_TMP_CHECK}")"
  ks_ck_original="$(ks_compress_path "$1")"
  ks_ck_status=0
  maxcso --quiet --decompress "${ks_ck_copy}" -o "${ks_ck_back}" >/dev/null 2>&1 &&
    cmp -s "${ks_ck_back}" "${ks_ck_original}" || ks_ck_status=1
  rm -f -- "${KS_TMP_CHECK}"
  KS_TMP_CHECK=""
  return "${ks_ck_status}"
}

ks_compress_fail() {
  ks_error "$1"
  ks_cleanup
  return 1
}

ks_compress_write() {
  ks_cw_dir="$(ks_trim_dir "$1")"
  if ! KS_TMP="$(mktemp "${ks_cw_dir}/.kirisute.XXXXXX")"; then
    KS_TMP=""
    ks_error "could not create a temporary file beside $1, so nothing was written."
    return 1
  fi
  ks_compress_run "$1" "${KS_TMP}" || ks_compress_fail "maxcso could not compress $1, so nothing was written." || return 1
  ks_compress_check "$1" "${KS_TMP}" ||
    ks_compress_fail "the compressed copy of $1 does not decompress to it, so it was deleted." || return 1
  ks_cw_mode="$(ks_trim_mode "$1")" || ks_cw_mode=""
  [ -z "${ks_cw_mode}" ] || chmod "${ks_cw_mode}" "${KS_TMP}" ||
    ks_compress_fail "could not give the compressed copy of $1 its permissions, so it was deleted." || return 1
  mv -f -- "${KS_TMP}" "$2" || ks_compress_fail "could not name the compressed copy $2, so it was deleted." || return 1
  KS_TMP=""
}

ks_compress_done() {
  KS_OUTPUT_SIZE="$(ks_file_bytes "$2")"
  KS_DONE=$((KS_DONE + 1))
  KS_SAVED=$((KS_SAVED + KS_ROM_SIZE - KS_OUTPUT_SIZE))
  ks_record compressed "" "$1"
  [ "${KS_JSON}" = no ] || return 0
  ks_cd_before="$(ks_human "${KS_ROM_SIZE}")"
  ks_cd_after="$(ks_human "${KS_OUTPUT_SIZE}")"
  ks_say "Compressed $1 to ${2##*/}, ${ks_cd_before} to ${ks_cd_after}."
}

ks_compress_process() {
  ks_rom_reason
  if [ -n "${KS_REASON}" ]; then
    ks_skip "$1" "${KS_REASON}"
    return 0
  fi
  if [ "${KS_SYSTEM}" != psp ]; then
    ks_skip "$1" "is not a PSP disc image, and only PSP disc images are compressed"
    return 0
  fi
  ks_cp_out="$(ks_compress_target "$1")"
  if [ -e "${ks_cp_out}" ] || [ -L "${ks_cp_out}" ]; then
    ks_skip "$1" "has a ${ks_cp_out##*/} already"
    return 0
  fi
  KS_OUTPUT="${ks_cp_out}"
  if [ "${KS_DRY_RUN}" = yes ]; then
    KS_DONE=$((KS_DONE + 1))
    ks_record would-compress "" "$1"
    ks_cp_label="$(ks_compress_label)"
    [ "${KS_JSON}" = yes ] || ks_say "Would compress $1 to ${ks_cp_out##*/} as ${ks_cp_label}."
    return 0
  fi
  if ! ks_compress_write "$1" "${ks_cp_out}"; then
    KS_FAILED=$((KS_FAILED + 1))
    ks_record failed "could not compress" "$1"
    return 0
  fi
  ks_compress_done "$1" "${ks_cp_out}"
}

ks_compress_plan() {
  ks_pl_label="$(ks_compress_label)"
  printf 'Plan:   compress each PSP disc image to %s in %s KiB blocks\n' "${ks_pl_label}" $((KS_BLOCK / 1024))
  if [ "${KS_FORMAT}" = cso2 ] && [ "${KS_LZ4_COST}" -eq 0 ]; then
    printf '        use LZ4 only where it is smaller than deflate\n'
  elif [ "${KS_FORMAT}" = cso2 ]; then
    printf '        use LZ4 where it costs at most %s%% more space\n' "${KS_LZ4_COST}"
  fi
  [ "${KS_BEST}" = no ] || printf '        best compression: one more slow compressor trial\n'
  printf '        keep each original and check that each copy decompresses to it\n'
  [ "${KS_DRY_RUN}" = no ] || printf '        dry run: list each copy and change nothing\n'
}

ks_compress_report() {
  ks_pr_count="$(ks_report_count "${KS_DONE}")"
  ks_pr_saved="$(ks_human "${KS_SAVED}")"
  if [ "${KS_FOUND}" -eq 0 ]; then
    printf 'No PSP disc image to compress.\n'
  elif [ "${KS_DRY_RUN}" = yes ]; then
    printf 'Dry run: %s would be compressed. Nothing was changed.\n' "${ks_pr_count}"
  elif [ "${KS_DONE}" -gt 0 ]; then
    printf 'Compressed %s and saved %s.\n' "${ks_pr_count}" "${ks_pr_saved}"
  else
    printf 'Nothing was compressed.\n'
  fi
}
