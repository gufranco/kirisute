#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
}

teardown() {
  ks_test_teardown
}

@test "sizes read in bytes, KiB, MiB and GiB" {
  # Arrange
  local sizes=""
  local bytes

  # Act
  for bytes in 0 1 512 1536 1572864 1610612736; do
    sizes="${sizes}$(ks_test_call ks_human "${bytes}");"
  done

  # Assert
  [[ "${sizes}" == "0 bytes;1 byte;512 bytes;1.5 KiB;1.5 MiB;1.5 GiB;" ]]
}

@test "an unknown unit code reads as unknown" {
  # Arrange
  local code=9

  # Act
  run ks_test_call ks_nds_unit_label "${code}"

  # Assert
  [[ "${output}" == "unknown" ]]
}

@test "a file at the root of the disk is copied beside it in /" {
  # Arrange
  local path="/game.nds"

  # Act
  run ks_test_call ks_trim_dir "${path}"

  # Assert
  [[ "${output}" == "/" ]]
}

@test "a bare file name is copied beside it in the current folder" {
  # Arrange
  local path="game.nds"

  # Act
  run ks_test_call ks_trim_dir "${path}"

  # Assert
  [[ "${output}" == "." ]]
}

@test "the cleanup removes the temporary file once and then does nothing" {
  # Arrange
  local temporary="${WORK}/.kirisute.test"
  printf 'x' >"${temporary}"

  # Act
  run ks_test_call call_cleanup "${temporary}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${temporary}" ]]
}
