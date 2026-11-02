#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.gba"
}

teardown() {
  ks_test_teardown
}

@test "a Game Boy Advance ROM is cut after its last data byte, on a 4-byte boundary" {
  # Arrange
  ks_test_gba "${ROM}" 16386 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16388
  [[ "${output}" == *"Trimmed ${ROM} from 64.0 KiB to 16.0 KiB."$'\n'"Trimmed 1 ROM and saved 48.0 KiB." ]]
}

@test "padding of 00 bytes is cut as well as FF" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536 000

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "padding longer than one read block is cut at the last data byte" {
  # Arrange
  ks_test_gba "${ROM}" 524292 3145728

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 524292
}

@test "a ROM that ends in data is already at its real size" {
  # Arrange
  ks_test_gba "${ROM}" 16384 16384

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${ROM} is already at its real size, 16.0 KiB."* ]]
  ks_test_size_is "${ROM}" 16384
}

@test "less than 512 bytes of padding is left in place" {
  # Arrange
  ks_test_gba "${ROM}" 16384 16892

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${ROM} is already at its real size"* ]]
  ks_test_size_is "${ROM}" 16892
}

@test "a Game Boy Advance file with a bad logo checksum stays as it is" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536 377 logo

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has a bad logo checksum and is not a Game Boy Advance ROM, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a Game Boy Advance file without the fixed header byte stays as it is" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536 377 fixed

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} lacks the fixed header byte of a Game Boy Advance ROM, so it stays as it is."* ]]
}

@test "a Game Boy Advance file with a bad header checksum stays as it is" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536 377 crc

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has a bad header checksum, so it stays as it is."* ]]
}

@test "a .gba file too small for a header stays as it is" {
  # Arrange
  printf 'not a rom' >"${ROM}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is too small to hold a Game Boy Advance header, so it stays as it is."* ]]
}

@test "--info prints a Game Boy Advance header" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536

  # Act
  run ks_test_run --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "File:   ${ROM}, 64.0 KiB" ]]
  [[ "${lines[1]}" == "Title:  KIRISUTE GBA" ]]
  [[ "${lines[2]}" == "Code:   AKSE" ]]
  [[ "${lines[3]}" == "Maker:  01" ]]
  [[ "${lines[4]}" == "Rev:    2" ]]
  [[ "${lines[5]}" == "Trim:   16.0 KiB, 48.0 KiB of padding" ]]
}

@test "--json --info reports a Game Boy Advance header" {
  # Arrange
  ks_test_gba "${ROM}" 16384 65536

  # Act
  run ks_test_run --json --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"{\"file\":\"${ROM}\",\"status\":\"info\",\"size\":65536,\"kind\":\"plain\",\"trimmed_size\":16384,\"title\":\"KIRISUTE GBA\",\"game_code\":\"AKSE\",\"maker_code\":\"01\",\"version\":2}]}" ]]
}

@test "a folder gives its .gba files as well as its .nds files" {
  # Arrange
  ks_test_gba "${WORK}/lib/a.GBA" 16384 65536
  ks_test_rom "${WORK}/lib/b.nds" plain 16384 0 65536

  # Act
  run ks_test_run "${WORK}/lib"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${WORK}/lib/a.GBA" 16384
  ks_test_size_is "${WORK}/lib/b.nds" 16384
  [[ "${output}" == *"Trimmed 2 ROMs and saved 96.0 KiB." ]]
}
