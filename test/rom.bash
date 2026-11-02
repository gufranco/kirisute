#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=test/bytes.bash
source "$(dirname "${BASH_SOURCE[0]}")/bytes.bash"

KS_TEST_HEADER_BYTES=544

ks_test_header() {
  local unit="$1"
  local ntr="$2"
  local twl="$3"
  local fault="$4"
  local crc
  ks_test_blank "${KS_TEST_HEADER_BYTES}"
  ks_test_put_text 0 "KIRISUTE"
  ks_test_put_text 12 "KSTE"
  KS_TEST_H[18]="${unit}"
  ks_test_put_u32 128 "${ntr}"
  ks_test_put_u32 528 "${twl}"
  ks_test_put_logo 192
  [[ "${fault}" != logo ]] || KS_TEST_H[200]=$(((KS_TEST_H[200] + 1) & 255))
  crc="$(ks_test_crc16 0 350)"
  [[ "${fault}" != crc ]] || crc=$(((crc + 1) & 65535))
  KS_TEST_H[350]=$((crc & 255))
  KS_TEST_H[351]=$((crc >> 8))
}

ks_test_main() {
  local path="$1"
  local kind="$2"
  local ntr="$3"
  local twl="$4"
  local total="$5"
  local pad="${6:-377}"
  local fault="${7:-}"
  local unit=0
  local end="${ntr}"
  case "${kind}" in
  dsi) unit=2 ;;
  dsi-only) unit=3 ;;
  *) : ;;
  esac
  [[ "${unit}" -eq 0 ]] || end="${twl}"
  [[ "${kind}" != rsa ]] || end=$((ntr + 136))
  ks_test_header "${unit}" "${ntr}" "${twl}" "${fault}"
  mkdir -p "$(dirname "${path}")"
  {
    ks_test_write_header "${KS_TEST_HEADER_BYTES}"
    ks_test_fill $((ntr - KS_TEST_HEADER_BYTES)) 132
    [[ "${kind}" != rsa ]] || {
      printf 'ac'
      ks_test_fill 134 21
    }
    [[ "${unit}" -eq 0 ]] || ks_test_fill $((twl - ntr)) 63
    ks_test_fill $((total - end)) "${pad}"
  } >"${path}"
}

ks_test_main "$@"
