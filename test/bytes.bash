#!/usr/bin/env bash
set -euo pipefail

KS_TEST_LOGO="030a11181f262d343b424950575e656c737a81888f969da4abb2b9c0c7ced5dce3eaf1f8040b121920272e353c434a51585f666d747b828990979ea5acb3bac1c8cfd6dde4ebf2f9050c131a21282f363d444b525960676e757c838a91989fa6adb4bbc2c9d0d7dee5ecf3fa060d141b222930373e454c535a61686f767d848b9299a0a7aeb5bcc3cad1d8dfe6edf400070e151c232a31383f468aa1"

ks_test_fill() {
  local count="$1"
  local octal="$2"
  [[ "${count}" -gt 0 ]] || return 0
  head -c "${count}" /dev/zero | LC_ALL=C tr '\000' "\\${octal}"
}

ks_test_blank() {
  local count="$1"
  local i
  KS_TEST_H=()
  for ((i = 0; i < count; i++)); do
    KS_TEST_H[i]=0
  done
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

ks_test_put_logo() {
  local at="$1"
  local i
  for ((i = 0; i < 156; i++)); do
    KS_TEST_H[at + i]=$((16#${KS_TEST_LOGO:i*2:2}))
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

ks_test_write_header() {
  local count="$1"
  local out=""
  local i byte
  for ((i = 0; i < count; i++)); do
    printf -v byte '\\%03o' "${KS_TEST_H[i]}"
    out+="${byte}"
  done
  printf '%b' "${out}"
}
