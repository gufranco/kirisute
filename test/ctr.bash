#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=test/bytes.bash
source "$(dirname "${BASH_SOURCE[0]}")/bytes.bash"

KS_TEST_CTR_HEADER=512
KS_TEST_CTR_UNIT=512
KS_TEST_CTR_FIRST=32

ks_test_ctr_executable() {
  local units="$1"
  local fault="$2"
  ks_test_blank "${KS_TEST_CTR_HEADER}"
  ks_test_put_text 256 "NCCH"
  [[ "${fault}" != magic ]] || ks_test_put_text 256 "NCCX"
  ks_test_put_u32 260 "${units}"
  ks_test_put_u32 280 1450704
  ks_test_put_u32 284 262144
  ks_test_put_text 336 "CTR-P-AKSE"
}

ks_test_ctr_image() {
  local fault="$1"
  shift
  local offset="${KS_TEST_CTR_FIRST}"
  local end=0
  local p=0
  local size
  ks_test_blank "${KS_TEST_CTR_HEADER}"
  ks_test_put_text 256 "NCSD"
  [[ "${fault}" != magic ]] || ks_test_put_text 256 "NCSX"
  ks_test_put_u32 264 1450752
  [[ "${fault}" == media ]] || ks_test_put_u32 268 262144
  [[ "${fault}" != media ]] || ks_test_put_u32 264 0
  [[ "${fault}" != nand ]] || KS_TEST_H[272]=1
  [[ "${fault}" != unit ]] || KS_TEST_H[398]=1
  for size in "$@"; do
    ks_test_put_u32 $((288 + 8 * p)) "${offset}"
    ks_test_put_u32 $((292 + 8 * p)) "${size}"
    end=$((offset + size))
    offset="${end}"
    p=$((p + 1))
  done
  [[ "${fault}" != overlap ]] || ks_test_put_u32 296 "${KS_TEST_CTR_FIRST}"
  ks_test_put_u32 260 "${end}"
  [[ "${fault}" != size ]] || ks_test_put_u32 260 $((end - 1))
  KS_TEST_CTR_END="${end}"
}

ks_test_ctr_main() {
  local path="$1"
  local kind="$2"
  local total="$3"
  local fault="$4"
  shift 4
  local unit="${KS_TEST_CTR_UNIT}"
  mkdir -p "$(dirname "${path}")"
  [[ "${fault}" != unit ]] || unit=$((unit * 2))
  if [[ "${kind}" == executable ]]; then
    ks_test_ctr_executable "$1" "${fault}"
    {
      ks_test_write_header "${KS_TEST_CTR_HEADER}"
      ks_test_fill $(($1 * unit - KS_TEST_CTR_HEADER)) 204
      ks_test_fill $((total - $1 * unit)) 377
    } >"${path}"
    return 0
  fi
  ks_test_ctr_image "${fault}" "$@"
  {
    ks_test_write_header "${KS_TEST_CTR_HEADER}"
    ks_test_fill $((KS_TEST_CTR_FIRST * unit - KS_TEST_CTR_HEADER)) 0
    ks_test_ctr_executable "$1" ""
    ks_test_write_header "${KS_TEST_CTR_HEADER}"
    ks_test_fill $((KS_TEST_CTR_END * unit - KS_TEST_CTR_FIRST * unit - KS_TEST_CTR_HEADER)) 204
    ks_test_fill $((total - KS_TEST_CTR_END * unit)) 377
  } >"${path}.full"
  head -c "${total}" "${path}.full" >"${path}"
  rm -f "${path}.full"
}

ks_test_ctr_main "$@"
