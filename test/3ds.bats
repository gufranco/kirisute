#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.3ds"
  CXI="${WORK}/game.cxi"
}

teardown() {
  ks_test_teardown
}

@test "a 3DS cartridge image is cut at the end of its last partition" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 "" 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 65536
  [[ "${output}" == *"Trimmed ${ROM} from 256.0 KiB to 64.0 KiB."$'\n'"Trimmed 1 ROM and saved 192.0 KiB." ]]
}

@test "a .cci file is read as a 3DS cartridge image" {
  # Arrange
  local rom="${WORK}/game.CCI"
  ks_test_ctr "${rom}" image 262144 "" 64 32

  # Act
  run ks_test_run "${rom}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${rom}" 65536
}

@test "a cartridge image counts partitions in the media unit its flags set" {
  # Arrange
  ks_test_ctr "${ROM}" image 524288 unit 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 131072
}

@test "a .3ds file without the NCSD magic stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 magic 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is not a 3DS cartridge image, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 262144
}

@test "a console NAND image is not taken for a cartridge image" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 nand 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is a 3DS NAND image, not a cartridge image, so it stays as it is."* ]]
}

@test "an image without a media ID stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 media 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has no media ID and is not a 3DS cartridge image, so it stays as it is."* ]]
}

@test "an image without a first partition stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 "" 0 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has no first partition, so it stays as it is."* ]]
}

@test "an image whose partitions overlap stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 overlap 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has partitions that overlap, so it stays as it is."* ]]
}

@test "an image whose partitions pass its declared size stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 size 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} declares partitions past its own image size, so it stays as it is."* ]]
}

@test "a .3ds file too small for a header stays as it is" {
  # Arrange
  printf 'not an image' >"${ROM}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is too small to hold a 3DS header, so it stays as it is."* ]]
}

@test "an image cut short before its first partition stays as it is" {
  # Arrange
  ks_test_ctr "${ROM}" image 8192 "" 64 32

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is shorter than its header says, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 8192
}

@test "--info prints a 3DS cartridge image's product code, media ID and partitions" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 "" 64 32

  # Act
  run ks_test_run --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "File:   ${ROM}, 256.0 KiB" ]]
  [[ "${lines[1]}" == "Code:   CTR-P-AKSE" ]]
  [[ "${lines[2]}" == "ID:     0004000000162300" ]]
  [[ "${lines[3]}" == "Parts:  2" ]]
  [[ "${lines[4]}" == "Trim:   64.0 KiB, 192.0 KiB of padding" ]]
}

@test "--json --info reports a 3DS cartridge image" {
  # Arrange
  ks_test_ctr "${ROM}" image 262144 "" 64 32

  # Act
  run ks_test_run --json --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"\"trimmed_size\":65536,\"title\":\"\",\"game_code\":\"CTR-P-AKSE\",\"media_id\":\"0004000000162300\",\"partitions\":2}]}" ]]
}

@test "a 3DS executable is cut to the size its header declares" {
  # Arrange
  ks_test_ctr "${CXI}" executable 131072 "" 64

  # Act
  run ks_test_run "${CXI}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${CXI}" 32768
  [[ "${output}" == *"Trimmed ${CXI} from 128.0 KiB to 32.0 KiB."* ]]
}

@test "a .cxi file without the NCCH magic stays as it is" {
  # Arrange
  ks_test_ctr "${CXI}" executable 131072 magic 64

  # Act
  run ks_test_run "${CXI}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${CXI} is not a 3DS executable, so it stays as it is."* ]]
}

@test "a 3DS executable that declares no size stays as it is" {
  # Arrange
  ks_test_ctr "${CXI}" executable 131072 "" 0

  # Act
  run ks_test_run "${CXI}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${CXI} declares a ROM size of 0, so it stays as it is."* ]]
}

@test "a .cxi file too small for a header stays as it is" {
  # Arrange
  printf 'not an executable' >"${CXI}"

  # Act
  run ks_test_run "${CXI}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${CXI} is too small to hold a 3DS executable header, so it stays as it is."* ]]
}

@test "--info prints a 3DS executable's product code and program ID" {
  # Arrange
  ks_test_ctr "${CXI}" executable 131072 "" 64

  # Act
  run ks_test_run --info "${CXI}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "Code:   CTR-P-AKSE" ]]
  [[ "${lines[2]}" == "ID:     00040000001622D0" ]]
}

@test "--json --info reports a 3DS executable's program ID" {
  # Arrange
  ks_test_ctr "${CXI}" executable 131072 "" 64

  # Act
  run ks_test_run --json --info "${CXI}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"\"game_code\":\"CTR-P-AKSE\",\"program_id\":\"00040000001622D0\"}]}" ]]
}

@test "a folder gives its .3ds, .cci and .cxi files" {
  # Arrange
  ks_test_ctr "${WORK}/lib/a.3ds" image 262144 "" 64 32
  ks_test_ctr "${WORK}/lib/b.cci" image 262144 "" 64 32
  ks_test_ctr "${WORK}/lib/c.cxi" executable 131072 "" 64

  # Act
  run ks_test_run "${WORK}/lib"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Trimmed 3 ROMs and saved 480.0 KiB." ]]
}
