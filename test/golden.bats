#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  LIB="${WORK}/library"
  ks_test_rom "${LIB}/plain.nds" plain 16384 0 65536
  ks_test_rom "${LIB}/download-play.nds" rsa 16384 0 65536
  ks_test_rom "${LIB}/dsi.nds" dsi 16384 32768 65536 000
  ks_test_rom "${LIB}/trimmed.nds" plain 16384 0 16384
  ks_test_rom "${LIB}/broken.nds" plain 16384 0 65536 377 crc
}

teardown() {
  ks_test_teardown
}

@test "a trim prints the same transcript as the recorded one" {
  # Arrange
  local flow=trim

  # Act
  run ks_test_run --backup "${LIB}"

  # Assert
  [[ "${status}" -eq 1 ]]
  ks_test_matches_golden "${flow}" "${output}"
}

@test "a dry run prints the same transcript as the recorded one" {
  # Arrange
  local flow=dry-run

  # Act
  run ks_test_run --dry-run --verify "${LIB}"

  # Assert
  [[ "${status}" -eq 1 ]]
  ks_test_matches_golden "${flow}" "${output}"
}

@test "an info run prints the same transcript as the recorded one" {
  # Arrange
  local flow=info

  # Act
  run ks_test_run --info "${LIB}"

  # Assert
  [[ "${status}" -eq 1 ]]
  ks_test_matches_golden "${flow}" "${output}"
}
