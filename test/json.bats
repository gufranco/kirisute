#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.nds"
}

teardown() {
  ks_test_teardown
}

@test "--json prints the result of a trim as one JSON object" {
  # Arrange
  ks_test_rom "${ROM}" rsa 16384 0 65536

  # Act
  run ks_test_run --json "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":false,\"info\":false,\"roms\":1,\"read\":0,\"trimmed\":1,\"already\":0,\"skipped\":0,\"failed\":0,\"saved\":49016,\"files\":[{\"file\":\"${ROM}\",\"status\":\"trimmed\",\"size\":65536,\"kind\":\"rsa\",\"trimmed_size\":16520}]}" ]]
}

@test "--json with --dry-run reports the cut and changes nothing" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run --json --dry-run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":true,"*"\"status\":\"would-trim\""* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "--json --info reports each header" {
  # Arrange
  ks_test_rom "${ROM}" dsi 16384 32768 65536

  # Act
  run ks_test_run --json --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":false,\"info\":true,\"roms\":1,\"read\":1,\"trimmed\":0,\"already\":0,\"skipped\":0,\"failed\":0,\"saved\":0,\"files\":[{\"file\":\"${ROM}\",\"status\":\"info\",\"size\":65536,\"kind\":\"dsi\",\"trimmed_size\":32768,\"title\":\"KIRISUTE\",\"game_code\":\"KSTE\",\"unit_code\":2}]}" ]]
}

@test "--json reports an already trimmed, a skipped and a failed ROM" {
  # Arrange
  ks_test_rom "${WORK}/a.nds" plain 16384 0 16384
  ks_test_rom "${WORK}/b.nds" plain 16384 0 65536 377 logo
  ks_test_rom "${WORK}/c.nds" plain 16384 0 65536
  ks_test_shim mktemp 'exit 1'

  # Act
  run ks_test_run --json "${WORK}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"\"roms\":3,\"read\":0,\"trimmed\":0,\"already\":1,\"skipped\":1,\"failed\":1,"* ]]
  [[ "${output}" == *"{\"file\":\"${WORK}/a.nds\",\"status\":\"already\",\"size\":16384,\"kind\":\"plain\",\"trimmed_size\":16384}"* ]]
  [[ "${output}" == *"{\"file\":\"${WORK}/b.nds\",\"status\":\"skipped\",\"size\":65536,\"reason\":\"has a bad logo checksum and is not a DS ROM\"}"* ]]
  [[ "${output}" == *"{\"file\":\"${WORK}/c.nds\",\"status\":\"failed\",\"size\":65536,\"kind\":\"plain\",\"trimmed_size\":16384,\"reason\":\"could not trim\"}"* ]]
}

@test "--json escapes quotes, backslashes and control characters in a file name" {
  # Arrange
  local name
  name="$(printf 'a"b\\c\td.nds')"
  ks_test_rom "${WORK}/${name}" plain 16384 0 65536

  # Act
  run ks_test_run --json "${WORK}/${name}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"\"file\":\"${WORK}/a\\\"b\\\\c\\u0009d.nds\""* ]]
}

@test "--json with nothing to trim reports zero ROMs" {
  # Arrange
  mkdir -p "${WORK}/empty"

  # Act
  run ks_test_run --json "${WORK}/empty"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":false,\"info\":false,\"roms\":0,\"read\":0,\"trimmed\":0,\"already\":0,\"skipped\":0,\"failed\":0,\"saved\":0,\"files\":[]}" ]]
}
