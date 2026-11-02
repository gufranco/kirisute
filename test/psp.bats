#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ISO="${WORK}/game.iso"
}

teardown() {
  ks_test_teardown
}

@test "a PSP ISO is cut to the volume size its descriptor declares" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ISO}" 131072
  [[ "${output}" == *"Trimmed ${ISO} from 256.0 KiB to 128.0 KiB."$'\n'"Trimmed 1 ROM and saved 128.0 KiB." ]]
}

@test "--info prints a PSP ISO's title, disc ID and volume" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144

  # Act
  run ks_test_run --info "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "File:   ${ISO}, 256.0 KiB" ]]
  [[ "${lines[1]}" == "Title:  Kirisute Test" ]]
  [[ "${lines[2]}" == "Code:   ULUS99999" ]]
  [[ "${lines[3]}" == "Volume: KIRISUTE_PSP" ]]
  [[ "${lines[4]}" == "Trim:   128.0 KiB, 128.0 KiB of padding" ]]
}

@test "--json --info reports a PSP ISO" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144

  # Act
  run ks_test_run --json --info "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"\"trimmed_size\":131072,\"title\":\"Kirisute Test\",\"game_code\":\"ULUS99999\",\"volume_id\":\"KIRISUTE_PSP\"}]}" ]]
}

@test "a PSP ISO without PARAM.SFO is still trimmed and shows no title" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 nosfo

  # Act
  run ks_test_run --info "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "Volume: KIRISUTE_PSP" ]]
  [[ "${output}" != *"Title:"* ]]
}

@test "an .iso file that is not ISO 9660 stays as it is" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 iso

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} is not an ISO 9660 disc image, so it stays as it is."* ]]
  ks_test_size_is "${ISO}" 262144
}

@test "an ISO that names no PSP system and has no PSP_GAME folder stays as it is" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 nogame

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} names no PSP system and has no PSP_GAME folder, so it is not a PSP disc image, so it stays as it is."* ]]
  ks_test_size_is "${ISO}" 262144
}

@test "an ISO whose system is PSP GAME is trimmed without a PSP_GAME folder" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 sysonly

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ISO}" 131072
}

@test "a system identifier written in quotes still names a PSP disc" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 quoted

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ISO}" 131072
}

@test "a UMD Video disc is trimmed like a game disc" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 video

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ISO}" 131072
}

@test "a homebrew ISO with a PSP_GAME folder and another system name is trimmed" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 homebrew

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ISO}" 131072
}

@test "a development DVD-R image says to join its layer files first" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 wrapper

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} is a development DVD-R image; join USER_L0.IMG and USER_L1.IMG, layer 0 first, and trim that, so it stays as it is."* ]]
}

@test "a PSP ISO with data past its declared volume stays as it is without --verify" {
  # Arrange
  ks_test_psp "${ISO}" 64 262144 tail

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} holds data at byte 131072, past its real size, so it stays as it is."* ]]
  ks_test_size_is "${ISO}" 262144
}

@test "an .iso file too small for a volume descriptor stays as it is" {
  # Arrange
  printf 'not a disc' >"${ISO}"

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} is too small to hold an ISO 9660 volume descriptor, so it stays as it is."* ]]
}

@test "an ISO shorter than its declared volume stays as it is" {
  # Arrange
  ks_test_psp "${ISO}" 64 100000

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} is shorter than its header says, so it stays as it is."* ]]
}

@test "an ISO that declares an empty volume stays as it is" {
  # Arrange
  ks_test_psp "${ISO}" 0 262144

  # Act
  run ks_test_run "${ISO}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ISO} declares a ROM size of 0, so it stays as it is."* ]]
}

@test "a folder gives its .iso files" {
  # Arrange
  ks_test_psp "${WORK}/lib/a.ISO" 64 262144

  # Act
  run ks_test_run "${WORK}/lib"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${WORK}/lib/a.ISO" 131072
}
