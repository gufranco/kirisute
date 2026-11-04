#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.nds"
  ks_test_rom "${ROM}" plain 16384 0 65536
  unset KODOUGU_THEME KODOUGU_ACCENT KIRISUTE_THEME NO_COLOR
  export KIRISUTE_TEST_GUM=1
  export KIRISUTE_TEST_GUM_LOG="${WORK}/gum.log"
  export KIRISUTE_TEST_GUM_ANSWERS="${WORK}/answers"
  export KIRISUTE_INTERACTIVE=1
  : >"${KIRISUTE_TEST_GUM_LOG}"
}

teardown() {
  ks_test_teardown
}

answers() {
  printf '%s\n' "$@" >"${KIRISUTE_TEST_GUM_ANSWERS}"
}

called() {
  grep -q -F -- "$1" "${KIRISUTE_TEST_GUM_LOG}"
}

@test "the ROM is asked for under the header and trimmed after a yes" {
  # Arrange
  answers "${ROM}" "yes"

  # Act
  run ks_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  [[ "${output}" == *"cut GBA, DS, DSi and 3DS ROMs and PSP ISOs to their real size"* ]]
  [[ "${output}" == *"Files:"* ]]
  [[ "${output}" == *"Trimmed 1 ROM and saved"* ]]
  called "input --header ROM file or folder"
  called "confirm Trim 1 ROM?"
}

@test "an empty ROM answer trims the current folder" {
  # Arrange
  answers "" "yes"
  cd "${WORK}"

  # Act
  run ks_test_run </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  called "--placeholder ."
}

@test "a no at the confirmation trims nothing" {
  # Arrange
  answers "no"

  # Act
  run ks_test_run "${ROM}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  ks_test_size_is "${ROM}" 65536
  [[ "${output}" == *"ERROR kirisute: stopped: nothing was changed."* ]]
}

@test "a dry run asks nothing" {
  # Arrange
  answers "<cancel>"

  # Act
  run ks_test_run --dry-run "${ROM}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 65536
  [[ "${output}" == *"Nothing was changed."* ]]
}

@test "rename asks before renaming" {
  # Arrange
  answers "yes"

  # Act
  run ks_test_run rename "${ROM}" </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Renamed 1 ROM."* ]]
  called "confirm Rename 1 ROM?"
}

@test "compress asks before compressing" {
  # Arrange
  local iso="${WORK}/disc.iso"
  ks_test_psp "${iso}" 64 262144
  answers "no"

  # Act
  run ks_test_run compress "${iso}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"stopped: nothing was changed."* ]]
  called "confirm Compress 1 disc image?"
}

@test "a skipped ROM makes the closing line a warning" {
  # Arrange
  local broken="${WORK}/broken.nds"
  printf 'not a rom' >"${broken}"
  answers "yes"

  # Act
  run ks_test_run "${broken}" "${ROM}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"WARN kirisute:"* ]]
}

@test "a cancelled ROM prompt stops the run" {
  # Arrange
  answers "<cancel>"

  # Act
  run ks_test_run </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "doctor draws its rows in a table" {
  # Arrange
  local expected="Tool"

  # Act
  run ks_test_run doctor </dev/null

  # Assert
  [[ "${output}" == *"${expected}"*"State"*"Detail"* ]]
}

@test "doctor reports a missing tool below the table" {
  # Arrange
  local farm
  farm="$(ks_test_farm od)"

  # Act
  run ks_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"ERROR kirisute: a required tool is missing."* ]]
}

@test "doctor fails without gum" {
  # Arrange
  local farm
  farm="$(ks_test_farm gum)"

  # Act
  KIRISUTE_TEST_GUM=0 run ks_test_run_path "${farm}" doctor </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"gum                missing  install with: brew install gum"* ]]
}

@test "version shows the version and platform as badges" {
  # Arrange
  local version
  version="$(ks_test_version)"

  # Act
  run ks_test_run version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "kirisute ${version} platform "* ]]
}

@test "help is formatted with gum" {
  # Arrange
  local expected="## Usage"

  # Act
  run ks_test_run help </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${expected}"* ]]
  called "format --theme pink"
}

@test "--theme picks the palette over the environment" {
  # Arrange
  local theme="nord"

  # Act
  KODOUGU_THEME=dracula KIRISUTE_THEME=gruvbox run ks_test_run --theme "${theme}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #88C0D0"
}

@test "--theme= with a value picks the palette" {
  # Arrange
  local option="--theme=tokyo-night"

  # Act
  run ks_test_run "${option}" version </dev/null

  # Assert
  [[ "${status}" -eq 0 ]]
  called "--background #7AA2F7"
}

@test "an unknown theme stops before anything runs" {
  # Arrange
  local theme="solarized"

  # Act
  KODOUGU_THEME="${theme}" run ks_test_run "${ROM}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"got: solarized"* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "--theme without a value stops with the usage hint" {
  # Arrange
  local option="--theme"

  # Act
  run ks_test_run version "${option}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"option '--theme' needs a value. run 'kirisute help' for usage."* ]]
}

@test "--theme after -- names a ROM" {
  # Arrange
  local option="--theme"

  # Act
  run ks_test_run --dry-run -- "${option}" </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"--theme"* ]]
}
