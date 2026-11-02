#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=test/bytes.bash
source "$(dirname "${BASH_SOURCE[0]}")/bytes.bash"

KS_TEST_GBA_HEADER=192

ks_test_gba_header() {
  local fault="$1"
  local sum=25
  local i
  ks_test_blank "${KS_TEST_GBA_HEADER}"
  ks_test_put_logo 4
  ks_test_put_text 160 "KIRISUTE GBA"
  ks_test_put_text 172 "AKSE"
  ks_test_put_text 176 "01"
  KS_TEST_H[178]=150
  KS_TEST_H[188]=2
  [[ "${fault}" != logo ]] || KS_TEST_H[10]=$(((KS_TEST_H[10] + 1) & 255))
  [[ "${fault}" != fixed ]] || KS_TEST_H[178]=0
  for ((i = 160; i < 189; i++)); do
    sum=$((sum + KS_TEST_H[i]))
  done
  KS_TEST_H[189]=$(((256 - sum % 256) % 256))
  [[ "${fault}" != crc ]] || KS_TEST_H[189]=$(((KS_TEST_H[189] + 1) & 255))
}

ks_test_gba_main() {
  local path="$1"
  local data="$2"
  local total="$3"
  local pad="${4:-377}"
  local fault="${5:-}"
  ks_test_gba_header "${fault}"
  mkdir -p "$(dirname "${path}")"
  {
    ks_test_write_header "${KS_TEST_GBA_HEADER}"
    ks_test_fill $((data - KS_TEST_GBA_HEADER)) 204
    ks_test_fill $((total - data)) "${pad}"
  } >"${path}"
}

ks_test_gba_main "$@"
