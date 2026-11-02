#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ISO="${WORK}/game.iso"
  ks_test_psp "${ISO}" 64 262144
}

teardown() {
  ks_test_teardown
}

ks_test_header_of() {
  local magic version block
  magic="$(head -c 4 "$1")"
  version="$(od -A n -t u1 -j 20 -N 1 "$1")"
  block="$(od -A n -t u4 -j 16 -N 4 "$1")"
  printf '%s v%s %s\n' "${magic}" "${version//[[:space:]]/}" "${block//[[:space:]]/}"
}

ks_test_header_is() {
  local found
  found="$(ks_test_header_of "$1")"
  [[ "${found}" == "$2" ]]
}

ks_test_text_blocks() {
  awk 'BEGIN { srand(7); for (i = 0; i < 60000; i++) { if (i % 3 == 0) printf "%d ", int(rand() * 1000); else printf "%s ", (rand() < 0.5 ? "alpha" : "omega") } }'
}

ks_test_decompresses_to() {
  maxcso --quiet --decompress "$1" -o "${WORK}/back.iso" >/dev/null 2>&1
  cmp -s "${WORK}/back.iso" "$2"
}

@test "compress writes a CSO v2 copy in 8 KiB blocks and keeps the original" {
  # Arrange
  local copy="${WORK}/game.cso"

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_header_is "${copy}" "CISO v2 8192"
  ks_test_size_is "${ISO}" 262144
  ks_test_decompresses_to "${copy}" "${ISO}"
  [[ "${output}" == *"Plan:   compress each PSP disc image to CSO v2 in 8 KiB blocks"$'\n'"        use LZ4 only where it is smaller than deflate"* ]]
  [[ "${output}" == *"Compressed ${ISO} to game.cso, 256.0 KiB to "* ]]
  ks_test_no_temporary "${WORK}"
}

@test "--format cso writes a CSO v1 copy" {
  # Arrange
  local copy="${WORK}/game.cso"

  # Act
  run ks_test_run compress --format cso "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_header_is "${copy}" "CISO v1 8192"
  [[ "${output}" != *"use LZ4"* ]]
  ks_test_decompresses_to "${copy}" "${ISO}"
}

@test "--format=zso writes a .zso copy" {
  # Arrange
  local copy="${WORK}/game.zso"

  # Act
  run ks_test_run compress --format=zso "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_header_is "${copy}" "ZISO v1 8192"
  ks_test_decompresses_to "${copy}" "${ISO}"
}

@test "--block sets the block size written in the header" {
  # Arrange
  local block=2048

  # Act
  run ks_test_run compress --block "${block}" "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_header_is "${WORK}/game.cso" "CISO v2 2048"
}

@test "--best and --lz4-cost still write a copy that decompresses to the original" {
  # Arrange
  local copy="${WORK}/game.cso"

  # Act
  run ks_test_run compress --best --lz4-cost=5 "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"        use LZ4 where it costs at most 5% more space"$'\n'"        best compression: one more slow compressor trial"* ]]
  ks_test_decompresses_to "${copy}" "${ISO}"
}

@test "the default CSO v2 copy matches the maxcso command known to boot on ARK, byte for byte" {
  # Arrange
  ks_test_psp "${ISO}" 512 1048576
  ks_test_text_blocks >"${WORK}/text.bin"
  dd if="${WORK}/text.bin" of="${ISO}" bs=2048 seek=32 conv=notrunc 2>/dev/null
  maxcso --quiet --format=cso2 --block=8192 --threads=8 --use-zlib --use-7zdeflate --use-lz4 --use-lz4brute "${ISO}" -o "${WORK}/known.cso"

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  cmp "${WORK}/known.cso" "${WORK}/game.cso"
}

@test "--best adds brute-force LZ4 to a ZSO copy" {
  # Arrange
  local copy="${WORK}/game.zso"

  # Act
  run ks_test_run compress --best --format zso "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_decompresses_to "${copy}" "${ISO}"
}

@test "--best adds Zopfli to a CSO v1 copy" {
  # Arrange
  local copy="${WORK}/game.cso"

  # Act
  run ks_test_run compress --best --format cso "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_decompresses_to "${copy}" "${ISO}"
}

@test "the format, block, cost and best mode come from the environment" {
  # Arrange
  local format=zso

  # Act
  KIRISUTE_FORMAT="${format}" KIRISUTE_BLOCK=4096 KIRISUTE_BEST=no run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_header_is "${WORK}/game.zso" "ZISO v1 4096"
}

@test "an unknown format is named" {
  # Arrange
  local format=dax

  # Act
  run ks_test_run compress --format "${format}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"--format must be cso, cso2 or zso, got: dax"* ]]
}

@test "an unsupported block size is named" {
  # Arrange
  local block=1000

  # Act
  run ks_test_run compress --block "${block}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"--block must be 2048, 4096, 8192 or 16384, got: 1000"* ]]
}

@test "an LZ4 cost above 100 is named" {
  # Arrange
  local cost=101

  # Act
  run ks_test_run compress --lz4-cost "${cost}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"--lz4-cost must be a whole number from 0 to 100, got: 101"* ]]
}

@test "an LZ4 cost that is not a number is named" {
  # Arrange
  local cost=x

  # Act
  run ks_test_run compress --lz4-cost "${cost}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"--lz4-cost must be a whole number from 0 to 100, got: x"* ]]
}

@test "an invalid value from the environment names its variable" {
  # Arrange
  local cost=500

  # Act
  KIRISUTE_LZ4_COST="${cost}" run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"KIRISUTE_LZ4_COST must be a whole number from 0 to 100, got: 500"* ]]
}

@test "an invalid best mode from the environment names its variable" {
  # Arrange
  local best=maybe

  # Act
  KIRISUTE_BEST="${best}" run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"KIRISUTE_BEST must be yes or no, got: maybe"* ]]
}

@test "--lz4-cost is refused for a format other than cso2" {
  # Arrange
  local format=zso

  # Act
  run ks_test_run compress --format "${format}" --lz4-cost 5 "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --lz4-cost applies only to --format cso2. run 'kirisute help' for usage." ]]
}

@test "a compress option is refused outside compress" {
  # Arrange
  local option=--best

  # Act
  run ks_test_run "${option}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --format, --block, --lz4-cost and --best apply only to compress. run 'kirisute help' for usage." ]]
}

@test "compress refuses --info" {
  # Arrange
  local option=--info

  # Act
  run ks_test_run compress "${option}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --info does not apply to compress. run 'kirisute help' for usage." ]]
}

@test "a value option without its value is refused" {
  # Arrange
  local option=--format

  # Act
  run ks_test_run compress "${ISO}" "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: option '--format' needs a value. run 'kirisute help' for usage." ]]
}

@test "an unknown option with a value is refused" {
  # Arrange
  local option=--speed=9

  # Act
  run ks_test_run compress "${option}" "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: unknown option '--speed'. run 'kirisute help' for usage." ]]
}

@test "a ROM that is not a PSP disc image is not compressed" {
  # Arrange
  ks_test_rom "${WORK}/game.nds" plain 16384 0 65536

  # Act
  run ks_test_run compress "${WORK}/game.nds"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${WORK}/game.nds is not a PSP disc image, and only PSP disc images are compressed, so it stays as it is."* ]]
}

@test "an .iso that fails its checks is not compressed" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 iso

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} is not an ISO 9660 disc image, so it stays as it is."* ]]
}

@test "a folder gives only its PSP disc images to compress" {
  # Arrange
  ks_test_rom "${WORK}/game.nds" plain 16384 0 65536

  # Act
  run ks_test_run compress "${WORK}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${WORK}/game.cso" ]]
  [[ "${output}" == *"Files:  1 ROM, 256.0 KiB"* ]]
}

@test "an existing copy is never overwritten" {
  # Arrange
  printf 'mine' >"${WORK}/game.cso"

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} has a game.cso already, so it stays as it is."$'\n'"Nothing was compressed." ]]
  local kept
  kept="$(cat "${WORK}/game.cso")"
  [[ "${kept}" == "mine" ]]
}

@test "compress --dry-run names each copy and writes nothing" {
  # Arrange
  local copy="${WORK}/game.cso"

  # Act
  run ks_test_run compress --dry-run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${copy}" ]]
  [[ "${output}" == *"        dry run: list each copy and change nothing"* ]]
  [[ "${output}" == *"Would compress ${ISO} to game.cso as CSO v2."$'\n'"Dry run: 1 ROM would be compressed. Nothing was changed." ]]
}

@test "compress --json reports each copy" {
  # Arrange
  local copy="${WORK}/game.zso"

  # Act
  run ks_test_run compress --json --format zso "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":false,\"format\":\"zso\",\"block\":8192,\"roms\":1,\"compressed\":1,\"skipped\":0,\"failed\":0,\"saved\":"*",\"files\":[{\"file\":\"${ISO}\",\"status\":\"compressed\",\"size\":262144,\"output\":\"${copy}\",\"output_size\":"*"}]}" ]]
}

@test "compress names nothing to do in an empty folder" {
  # Arrange
  mkdir -p "${WORK}/empty"

  # Act
  run ks_test_run compress "${WORK}/empty"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No PSP disc image to compress." ]]
}

@test "compress without maxcso says how to install it" {
  # Arrange
  local farm
  farm="$(ks_test_farm maxcso)"

  # Act
  run ks_test_run_path "${farm}" compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"compress needs maxcso: brew install gufranco/tap/maxcso"* ]]
}

@test "a copy maxcso cannot write leaves nothing behind" {
  # Arrange
  ks_test_shim maxcso 'exit 1'

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"maxcso could not compress ${ISO}, so nothing was written."* ]]
  [[ ! -e "${WORK}/game.cso" ]]
  ks_test_no_temporary "${WORK}"
}

@test "a copy that does not decompress to the original is deleted" {
  # Arrange
  ks_test_shim maxcso "case \"\$*\" in *--decompress*) for last; do :; done; printf x >\"\${last}\"; exit 0 ;; esac; exec \"\$REAL\" \"\$@\""

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"the compressed copy of ${ISO} does not decompress to it, so it was deleted."* ]]
  [[ ! -e "${WORK}/game.cso" ]]
  ks_test_no_temporary "${WORK}"
}

@test "a copy is refused when no temporary file can be made beside the image" {
  # Arrange
  ks_test_shim mktemp 'exit 1'

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not create a temporary file beside ${ISO}, so nothing was written."* ]]
}

@test "a copy is deleted when no room is left to check it" {
  # Arrange
  ks_test_shim mktemp "[ -e \"${WORK}/made\" ] && exit 1; : >\"${WORK}/made\"; exec \"\$REAL\" \"\$@\""

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"does not decompress to it, so it was deleted."* ]]
  ks_test_no_temporary "${WORK}"
}

@test "a copy is deleted when it cannot take the original's permissions" {
  # Arrange
  ks_test_shim chmod 'exit 1'

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not give the compressed copy of ${ISO} its permissions, so it was deleted."* ]]
  ks_test_no_temporary "${WORK}"
}

@test "a copy is deleted when it cannot take its name" {
  # Arrange
  ks_test_shim mv 'exit 1'

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not name the compressed copy ${WORK}/game.cso, so it was deleted."* ]]
  ks_test_no_temporary "${WORK}"
}

@test "a copy takes the original's permissions" {
  # Arrange
  local found
  chmod 640 "${ISO}"

  # Act
  run ks_test_run compress "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  found="$(find "${WORK}/game.cso" -perm 640)"
  [[ "${found}" == "${WORK}/game.cso" ]]
}

@test "an image whose name starts with a hyphen is compressed" {
  # Arrange
  mv -f "${ISO}" "${WORK}/-game.iso"

  # Act
  run bash -c 'cd "$1" && PATH="$2" sh "$3" compress -- -game.iso' _ "${WORK}" "${PATH}" "${REPO_DIR}/bin/kirisute"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${WORK}/-game.cso" ]]
}

@test "doctor fails and names a missing maxcso" {
  # Arrange
  local farm
  farm="$(ks_test_farm maxcso)"

  # Act
  run ks_test_run_path "${farm}" doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"maxcso             missing  required, brew install gufranco/tap/maxcso"* ]]
}
