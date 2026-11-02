#!/usr/bin/env bash
set -euo pipefail

KS_TEST_LOGO="030a11181f262d343b424950575e656c737a81888f969da4abb2b9c0c7ced5dce3eaf1f8040b121920272e353c434a51585f666d747b828990979ea5acb3bac1c8cfd6dde4ebf2f9050c131a21282f363d444b525960676e757c838a91989fa6adb4bbc2c9d0d7dee5ecf3fa060d141b222930373e454c535a61686f767d848b9299a0a7aeb5bcc3cad1d8dfe6edf400070e151c232a31383f468aa1"
KS_TEST_HEADER_BYTES=544

ks_test_fill() {
  local count="$1"
  local octal="$2"
  [[ "${count}" -gt 0 ]] || return 0
  head -c "${count}" /dev/zero | LC_ALL=C tr '\000' "\\${octal}"
}

ks_test_put_u32() {
  local at="$1"
  local value="$2"
  KS_TEST_H[at]=$((value & 255))
  KS_TEST_H[at + 1]=$(((value >> 8) & 255))
  KS_TEST_H[at + 2]=$(((value >> 16) & 255))
  KS_TEST_H[at + 3]=$(((value >> 24) & 255))
}

ks_test_put_text() {
  local at="$1"
  local text="$2"
  local i char code
  for ((i = 0; i < ${#text}; i++)); do
    char="${text:i:1}"
    printf -v code '%d' "'${char}"
    KS_TEST_H[at + i]="${code}"
  done
}

ks_test_crc16() {
  local start="$1"
  local count="$2"
  local crc=65535
  local i k
  for ((i = start; i < start + count; i++)); do
    crc=$((crc ^ KS_TEST_H[i]))
    for ((k = 0; k < 8; k++)); do
      if ((crc & 1)); then
        crc=$(((crc >> 1) ^ 40961))
      else
        crc=$((crc >> 1))
      fi
    done
  done
  printf '%d\n' "${crc}"
}

ks_test_header() {
  local unit="$1"
  local ntr="$2"
  local twl="$3"
  local fault="$4"
  local i crc
  KS_TEST_H=()
  for ((i = 0; i < KS_TEST_HEADER_BYTES; i++)); do
    KS_TEST_H[i]=0
  done
  ks_test_put_text 0 "KIRISUTE"
  ks_test_put_text 12 "KSTE"
  KS_TEST_H[18]="${unit}"
  ks_test_put_u32 128 "${ntr}"
  ks_test_put_u32 528 "${twl}"
  for ((i = 0; i < 156; i++)); do
    KS_TEST_H[192 + i]=$((16#${KS_TEST_LOGO:i*2:2}))
  done
  [[ "${fault}" != logo ]] || KS_TEST_H[200]=$(((KS_TEST_H[200] + 1) & 255))
  crc="$(ks_test_crc16 0 350)"
  [[ "${fault}" != crc ]] || crc=$(((crc + 1) & 65535))
  KS_TEST_H[350]=$((crc & 255))
  KS_TEST_H[351]=$((crc >> 8))
}

ks_test_write_header() {
  local out=""
  local i byte
  for ((i = 0; i < KS_TEST_HEADER_BYTES; i++)); do
    printf -v byte '\\%03o' "${KS_TEST_H[i]}"
    out+="${byte}"
  done
  printf '%b' "${out}"
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
    ks_test_write_header
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
