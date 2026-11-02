#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=test/bytes.bash
source "$(dirname "${BASH_SOURCE[0]}")/bytes.bash"

KS_TEST_SECTOR=2048
KS_TEST_PSP_LEAD=24

ks_test_put_both32() {
  local at="$1"
  local value="$2"
  ks_test_put_u32 "${at}" "${value}"
  KS_TEST_H[at + 4]=$(((value >> 24) & 255))
  KS_TEST_H[at + 5]=$(((value >> 16) & 255))
  KS_TEST_H[at + 6]=$(((value >> 8) & 255))
  KS_TEST_H[at + 7]=$((value & 255))
}

ks_test_record() {
  local at="$1"
  local name="$2"
  local extent="$3"
  local length="$4"
  local flags="$5"
  local size=$((33 + ${#name}))
  size=$((size + size % 2))
  KS_TEST_H[at]="${size}"
  ks_test_put_both32 $((at + 2)) "${extent}"
  ks_test_put_both32 $((at + 10)) "${length}"
  KS_TEST_H[at + 25]="${flags}"
  KS_TEST_H[at + 32]="${#name}"
  ks_test_put_text $((at + 33)) "${name}"
  KS_TEST_RECORD_END=$((at + size))
}

ks_test_descriptor() {
  local space="$1"
  local fault="$2"
  local at=$((16 * KS_TEST_SECTOR))
  KS_TEST_H[at]=1
  ks_test_put_text $((at + 1)) "CD001"
  [[ "${fault}" != iso ]] || ks_test_put_text $((at + 1)) "CD002"
  KS_TEST_H[at + 6]=1
  local system="PSP GAME"
  case "${fault}" in
  nogame | homebrew | wrapper) system="LINUX" ;;
  quoted) system='"PSP GAME"' ;;
  video) system="UMD VIDEO" ;;
  *) : ;;
  esac
  ks_test_put_text $((at + 8)) "$(printf '%-32s' "${system}")"
  ks_test_put_text $((at + 40)) "KIRISUTE_PSP                    "
  ks_test_put_both32 $((at + 80)) "${space}"
  KS_TEST_H[at + 128]=0
  KS_TEST_H[at + 129]=8
  KS_TEST_H[at + 130]=8
  ks_test_record $((at + 156)) $'\001' 20 4096 2
  KS_TEST_H[at + 156 + 33]=0
}

ks_test_sfo() {
  local at=$((23 * KS_TEST_SECTOR))
  ks_test_put_text $((at + 1)) "PSF"
  KS_TEST_H[at + 4]=1
  KS_TEST_H[at + 5]=1
  ks_test_put_u32 $((at + 8)) 52
  ks_test_put_u32 $((at + 12)) 68
  ks_test_put_u32 $((at + 16)) 2
  KS_TEST_H[at + 20]=0
  KS_TEST_H[at + 22]=4
  KS_TEST_H[at + 23]=2
  ks_test_put_u32 $((at + 24)) 10
  ks_test_put_u32 $((at + 28)) 16
  ks_test_put_u32 $((at + 32)) 0
  KS_TEST_H[at + 36]=8
  KS_TEST_H[at + 38]=4
  KS_TEST_H[at + 39]=2
  ks_test_put_u32 $((at + 40)) 14
  ks_test_put_u32 $((at + 44)) 128
  ks_test_put_u32 $((at + 48)) 16
  ks_test_put_text $((at + 52)) "DISC_ID"
  ks_test_put_text $((at + 60)) "TITLE"
  ks_test_put_text $((at + 68)) "ULUS99999"
  ks_test_put_text $((at + 84)) "Kirisute Test"
}

ks_test_tree() {
  local fault="$1"
  local root=$((20 * KS_TEST_SECTOR))
  local game_name="PSP_GAME"
  ks_test_record "${root}" $'\001' 20 4096 2
  KS_TEST_H[root + 33]=0
  ks_test_record "${KS_TEST_RECORD_END}" $'\001' 20 4096 2
  case "${fault}" in
  nogame | sysonly | quoted | video) game_name="PSP_DATA" ;;
  *) : ;;
  esac
  if [[ "${fault}" == wrapper ]]; then
    ks_test_record $((root + KS_TEST_SECTOR)) "USER_L0.IMG;1" 24 2048 0
    return 0
  fi
  ks_test_record $((root + KS_TEST_SECTOR)) "${game_name}" 22 2048 2
  [[ "${fault}" == nosfo ]] || ks_test_record $((22 * KS_TEST_SECTOR)) "PARAM.SFO;1" 23 2048 0
  ks_test_sfo
}

ks_test_psp_main() {
  local path="$1"
  local space="$2"
  local total="$3"
  local fault="${4:-}"
  local lead=$((KS_TEST_PSP_LEAD * KS_TEST_SECTOR))
  local tail=0
  [[ "${fault}" != tail ]] || tail=204
  ks_test_blank "${lead}"
  ks_test_descriptor "${space}" "${fault}"
  ks_test_tree "${fault}"
  mkdir -p "$(dirname "${path}")"
  {
    ks_test_write_header "${lead}"
    ks_test_fill $((space * KS_TEST_SECTOR - lead)) 204
    ks_test_fill $((total - space * KS_TEST_SECTOR)) "${tail}"
  } >"${path}.full"
  head -c "${total}" "${path}.full" >"${path}"
  rm -f "${path}.full"
}

ks_test_psp_main "$@"
