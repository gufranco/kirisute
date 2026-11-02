#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.nds"
  NAMED="${WORK}/KIRISUTE (KSTE).nds"
}

teardown() {
  ks_test_teardown
}

@test "rename names a DS ROM after the title and game code in its header" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${NAMED}" ]]
  [[ ! -e "${ROM}" ]]
  [[ "${output}" == *"Plan:   rename each ROM after the title and code in its header"* ]]
  [[ "${output}" == *"Renamed ${ROM} to KIRISUTE (KSTE).nds."$'\n'"Renamed 1 ROM." ]]
}

@test "rename keeps a Game Boy Advance title with its spaces" {
  # Arrange
  ks_test_gba "${WORK}/a.gba" 16384 65536

  # Act
  run ks_test_run rename "${WORK}/a.gba"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${WORK}/KIRISUTE GBA (AKSE).gba" ]]
}

@test "rename uses the product code alone for a 3DS image, which has no title" {
  # Arrange
  ks_test_ctr "${WORK}/a.3ds" image 262144 "" 64 32

  # Act
  run ks_test_run rename "${WORK}/a.3ds"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${WORK}/CTR-P-AKSE.3ds" ]]
}

@test "rename writes the extension in lowercase" {
  # Arrange
  ks_test_rom "${WORK}/game.NDS" plain 16384 0 65536

  # Act
  run ks_test_run rename "${WORK}/game.NDS"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${NAMED}" ]]
}

@test "rename gives a file without an extension no extension" {
  # Arrange
  ks_test_rom "${WORK}/game" plain 16384 0 65536

  # Act
  run ks_test_run rename "${WORK}/game"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${WORK}/KIRISUTE (KSTE)" ]]
}

@test "rename works on a bare file name in the current folder" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run bash -c 'cd "$1" && PATH="$2" sh "$3" rename game.nds' _ "${WORK}" "${PATH}" "${REPO_DIR}/bin/kirisute"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${NAMED}" ]]
  [[ "${output}" == *"Renamed game.nds to KIRISUTE (KSTE).nds."* ]]
}

@test "rename --dry-run lists each new name and changes nothing" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename --dry-run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -f "${ROM}" ]]
  [[ ! -e "${NAMED}" ]]
  [[ "${output}" == *"        dry run: list each new name and change nothing"* ]]
  [[ "${output}" == *"Would rename ${ROM} to KIRISUTE (KSTE).nds."$'\n'"Dry run: 1 ROM would be renamed. Nothing was changed." ]]
}

@test "a ROM already named after its header is left as it is" {
  # Arrange
  ks_test_rom "${NAMED}" plain 16384 0 65536

  # Act
  run ks_test_run rename "${NAMED}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${NAMED} is already named after its header."$'\n'"Nothing to rename: every ROM is already named after its header." ]]
}

@test "a rename that only changes the letter case goes through" {
  # Arrange
  local lower="${WORK}/kirisute (kste).nds"
  ks_test_rom "${lower}" plain 16384 0 65536

  # Act
  run ks_test_run rename "${lower}"

  # Assert
  [[ "${status}" -eq 0 ]]
  local names
  names="$(ls "${WORK}")"
  [[ "${names}" == *"KIRISUTE (KSTE).nds"* ]]
  [[ "${names}" != *"kirisute (kste).nds"* ]]
}

@test "rename never takes a name another file already has" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  printf 'mine' >"${NAMED}"

  # Act
  run ks_test_run rename "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} cannot take the name KIRISUTE (KSTE).nds, which another file has, so it stays as it is."* ]]
  [[ "${output}" == *"Nothing was renamed." ]]
  [[ -f "${ROM}" ]]
  local kept
  kept="$(cat "${NAMED}")"
  [[ "${kept}" == "mine" ]]
}

@test "rename skips a file whose header fails its checks" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536 377 logo

  # Act
  run ks_test_run rename "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has a bad logo checksum and is not a DS ROM, so it stays as it is."* ]]
}

@test "rename skips a ROM whose header holds no title or code" {
  # Arrange
  ks_test_psp "${WORK}/a.iso" 64 262144 nosfo

  # Act
  run ks_test_run rename "${WORK}/a.iso"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${WORK}/a.iso has no title or code in its header to name it by, so it stays as it is."* ]]
}

@test "a rename that mv refuses is counted as failed" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim mv 'exit 1'

  # Act
  run ks_test_run rename "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"Nothing was renamed." ]]
  [[ -f "${ROM}" ]]
}

@test "rename --json reports each new name" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename --json "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "{\"dry_run\":false,\"roms\":1,\"renamed\":1,\"already\":0,\"skipped\":0,\"failed\":0,\"files\":[{\"file\":\"${ROM}\",\"status\":\"renamed\",\"size\":65536,\"new_name\":\"${NAMED}\"}]}" ]]
}

@test "rename finds nothing to rename in an empty folder" {
  # Arrange
  mkdir -p "${WORK}/empty"

  # Act
  run ks_test_run rename "${WORK}/empty"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No ROM to rename." ]]
}

@test "rename refuses --info" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename --info "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --info does not apply to rename. run 'kirisute help' for usage." ]]
}

@test "rename refuses --verify" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename --no-verify "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --verify and --no-verify do not apply to rename. run 'kirisute help' for usage." ]]
}

@test "rename refuses --backup" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run rename --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: --backup and --no-backup do not apply to rename. run 'kirisute help' for usage." ]]
}
