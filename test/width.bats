#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d /tmp/ks-width.XXXXXX)"
  WORK="$(cd "${WORK}" && pwd -P)"
  TARGET="${WORK}/target"
  mkdir -p "${TARGET}"
}

teardown() {
  rm -rf "${WORK}"
}

widest_line() {
  awk '{ if (length($0) > widest) { widest = length($0) } } END { print widest + 0 }'
}

@test "help never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(ks_test_run help)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "version never prints a line wider than 80 columns" {
  # Arrange
  local page widest

  # Act
  page="$(ks_test_run version)"

  # Assert
  widest="$(printf '%s\n' "${page}" | widest_line)"
  [[ "${widest}" -le 80 ]]
}

@test "an error stays on one line, however long" {
  # Arrange
  local message="the trimmed copy of a ROM with a very long name could not be written, so the ROM stays as it was"

  # Act
  run ks_test_call ks_error "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "kirisute: ${message}" ]]
}

@test "a doctor row stays on one line, however long" {
  # Arrange
  local expected="mkdir              ok       /opt/homebrew/opt/uutils-coreutils/libexec/uubin/mkdir, uutils 0.12.0"

  # Act
  run ks_test_call ks_doctor_row "mkdir" ok "/opt/homebrew/opt/uutils-coreutils/libexec/uubin/mkdir, uutils 0.12.0"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "internal KS_ variables from the environment change nothing" {
  # Arrange
  ks_test_rom "${TARGET}/game.nds" plain 16384 0 65536

  # Act
  KS_DRY_RUN=yes KS_DEPTH_MAX=0 KS_BACKUP=no run ks_test_run "${TARGET}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Trimmed 1 ROM and saved 48.0 KiB."* ]]
  ks_test_size_is "${TARGET}/game.nds" 16384
  ks_test_size_is "${TARGET}/game.nds.bak" 65536
}
