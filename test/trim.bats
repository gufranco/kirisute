#!/usr/bin/env bats
# shellcheck disable=SC2016

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.nds"
}

teardown() {
  ks_test_teardown
}

@test "a DS ROM is cut to the ROM size its header declares" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  [[ "${output}" == *"Trimmed ${ROM} from 64.0 KiB to 16.0 KiB."$'\n'"The original of ${ROM} is kept as ${ROM}.bak."$'\n'"Trimmed 1 ROM and saved 48.0 KiB." ]]
}

@test "a ROM given by name is read as a DS ROM whatever its extension" {
  # Arrange
  local rom="${WORK}/game.bin"
  ks_test_rom "${rom}" plain 16384 0 65536

  # Act
  run ks_test_run "${rom}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${rom}" 16384
  [[ "${output}" == *"Trimmed ${rom} from 64.0 KiB to 16.0 KiB."* ]]
}

@test "a DS ROM keeps its download-play certificate" {
  # Arrange
  ks_test_rom "${ROM}" rsa 16384 0 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16520
  [[ "${output}" == *"keeping its download-play certificate."* ]]
}

@test "a DSi-enhanced ROM keeps its DSi area" {
  # Arrange
  ks_test_rom "${ROM}" dsi 16384 32768 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 32768
  [[ "${output}" == *"keeping its DSi area."* ]]
}

@test "a DSi-only ROM keeps its DSi area" {
  # Arrange
  ks_test_rom "${ROM}" dsi-only 16384 40960 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 40960
}

@test "the trimmed ROM keeps every byte up to its real size" {
  # Arrange
  local expected="${WORK}/expected.bin"
  ks_test_rom "${ROM}" rsa 16384 0 65536
  head -c 16520 <"${ROM}" >"${expected}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  cmp "${expected}" "${ROM}"
}

@test "a trimmed ROM keeps its permissions" {
  # Arrange
  local found
  ks_test_rom "${ROM}" plain 16384 0 65536
  chmod 640 "${ROM}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  found="$(find "${ROM}" -perm 640)"
  [[ "${found}" == "${ROM}" ]]
}

@test "a ROM already at its real size is left alone" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 16384

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"${ROM} is already at its real size, 16.0 KiB."$'\n'"Nothing to trim: every ROM is already at its real size." ]]
}

@test "a DS ROM whose padding starts right after its data has no certificate read" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 16385

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "a file too small for a header stays as it is" {
  # Arrange
  printf 'not a rom' >"${ROM}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"kirisute: warning: ${ROM} is too small to hold a DS header, so it stays as it is."* ]]
  [[ "${output}" == *"Nothing was trimmed." ]]
}

@test "a file with a bad logo checksum stays as it is" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536 377 logo

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has a bad logo checksum and is not a DS ROM, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a file with a bad header checksum stays as it is" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536 377 crc

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has a bad header checksum, so it stays as it is."* ]]
}

@test "a DS ROM that declares a size of 0 stays as it is" {
  # Arrange
  ks_test_rom "${ROM}" plain 0 0 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} declares a ROM size of 0, so it stays as it is."* ]]
}

@test "a DSi ROM that declares a DSi size of 0 stays as it is" {
  # Arrange
  ks_test_rom "${ROM}" dsi 16384 0 65536

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} declares a ROM size of 0, so it stays as it is."* ]]
}

@test "a ROM shorter than its header says stays as it is" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 16384
  head -c 8192 <"${ROM}" >"${ROM}.cut"
  mv -f "${ROM}.cut" "${ROM}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} is shorter than its header says, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 8192
}

@test "--verify trims a ROM padded with 00 and FF only" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 32768 000
  ks_test_rom "${WORK}/ff.nds" plain 16384 0 32768 377

  # Act
  run ks_test_run --verify "${ROM}" "${WORK}/ff.nds"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  ks_test_size_is "${WORK}/ff.nds" 16384
}

@test "--verify keeps a ROM whose padding holds data and names the first byte" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 32768 000
  printf '\001' | dd of="${ROM}" bs=1 seek=20000 conv=notrunc 2>/dev/null

  # Act
  run ks_test_run --verify "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} holds data at byte 20000, past its real size, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 32768
}

@test "without --verify a ROM is trimmed whatever its padding holds" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 32768 132

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "--backup keeps the original beside the trimmed ROM" {
  # Arrange
  local original="${WORK}/original.nds"
  ks_test_rom "${ROM}" plain 16384 0 65536
  cp "${ROM}" "${original}"

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  cmp "${original}" "${ROM}.bak"
}

@test "--backup never overwrites an earlier backup" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  printf 'old' >"${ROM}.bak"
  local original="${WORK}/original.nds"
  cp "${ROM}" "${original}"

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"The original of ${ROM} is kept as ${ROM}.bak.1."* ]]
  ks_test_size_is "${ROM}.bak" 3
  cmp "${original}" "${ROM}.bak.1"
  ks_test_size_is "${ROM}" 16384
}

@test "--backup treats a dangling link where the backup goes as taken" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ln -s "${WORK}/nowhere" "${ROM}.bak"

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -L "${ROM}.bak" ]]
  ks_test_size_is "${ROM}.bak.1" 65536
}

@test "--backup keeps a ROM whose hundred backup names are all taken" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  local count=1
  : >"${ROM}.bak"
  while [[ "${count}" -lt 100 ]]; do
    : >"${ROM}.bak.${count}"
    count=$((count + 1))
  done

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"${ROM} has ${ROM}.bak to ${ROM}.bak.99 already, so it stays as it is."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a trim keeps the original as a backup by default" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  local original="${WORK}/original.nds"
  cp "${ROM}" "${original}"

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  cmp "${original}" "${ROM}.bak"
}

@test "--dry-run lists each cut and changes nothing" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  printf 'old' >"${ROM}.bak"

  # Act
  run ks_test_run --dry-run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"        dry run: list each cut and change nothing"* ]]
  [[ "${output}" == *"Would trim ${ROM} from 64.0 KiB to 16.0 KiB."$'\n'"Dry run: 1 ROM would be trimmed, saving 48.0 KiB. Nothing was changed." ]]
  ks_test_size_is "${ROM}" 65536
}

@test "--info prints the header and changes nothing" {
  # Arrange
  ks_test_rom "${ROM}" rsa 16384 0 65536

  # Act
  run ks_test_run --info "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "File:   ${ROM}, 64.0 KiB" ]]
  [[ "${lines[1]}" == "Title:  KIRISUTE" ]]
  [[ "${lines[2]}" == "Code:   KSTE" ]]
  [[ "${lines[3]}" == "Unit:   0x00, NTR, DS" ]]
  [[ "${lines[4]}" == "Cert:   yes, download play" ]]
  [[ "${lines[5]}" == "Trim:   16.1 KiB, 47.9 KiB of padding" ]]
  [[ "${lines[6]}" == "Read 1 ROM." ]]
  ks_test_size_is "${ROM}" 65536
}

@test "--info names the unit of a DSi-enhanced and a DSi-only ROM" {
  # Arrange
  ks_test_rom "${WORK}/a.nds" dsi 16384 32768 65536
  ks_test_rom "${WORK}/b.nds" dsi-only 16384 32768 32768

  # Act
  run ks_test_run --info "${WORK}/a.nds" "${WORK}/b.nds"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Unit:   0x02, NTR and TWL, DSi enhanced"$'\n'"Cert:   none"* ]]
  [[ "${output}" == *"Unit:   0x03, TWL, DSi only"* ]]
  [[ "${output}" == *"Read 2 ROMs." ]]
}

@test "--info counts only the ROMs it could read" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  printf 'junk' >"${WORK}/junk.nds"

  # Act
  run ks_test_run --info "${WORK}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"Read 1 of 2 ROMs." ]]
}

@test "a run with some ROMs skipped trims the rest" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_rom "${WORK}/bad.nds" plain 16384 0 65536 377 logo

  # Act
  run ks_test_run "${WORK}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"Trimmed 1 of 2 ROMs and saved 48.0 KiB." ]]
  ks_test_size_is "${ROM}" 16384
}

@test "a temporary file that cannot be made leaves the ROM as it was" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim mktemp 'exit 1'

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"kirisute: could not create a temporary file beside ${ROM}, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a copy that cannot be written leaves the ROM and no temporary file" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim head 'exit 1'

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not write the trimmed copy of ${ROM}, so it stays as it was."* ]]
  ks_test_no_temporary "${WORK}"
  ks_test_size_is "${ROM}" 65536
}

@test "a short copy leaves the ROM as it was" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim head 'exec "$REAL" -c 100'

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"wrote 100 of 16384 bytes of ${ROM}, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "permissions that cannot be copied leave the ROM as it was" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim chmod 'exit 1'

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not give the trimmed copy of ${ROM} its permissions, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a ROM is trimmed when no stat can read its permissions" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim stat 'exit 1'

  # Act
  run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "a rename that fails leaves the ROM as it was" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim mv 'exit 1'

  # Act
  run ks_test_run --no-backup "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not put the trimmed copy in place of ${ROM}, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
  ks_test_no_temporary "${WORK}"
}

@test "a backup that cannot be made leaves the ROM as it was" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim mv 'case "$4" in *.bak) exit 1 ;; esac; exec "$REAL" "$@"'

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not keep ${ROM} as ${ROM}.bak, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
}

@test "a failed swap after the backup puts the original back" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536
  ks_test_shim mv 'case "$3" in */.kirisute.*) exit 1 ;; esac; exec "$REAL" "$@"'

  # Act
  run ks_test_run --backup "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"could not put the trimmed copy in place of ${ROM}, so it stays as it was."* ]]
  ks_test_size_is "${ROM}" 65536
  [[ ! -e "${ROM}.bak" ]]
}

@test "a ROM given by a bare name is trimmed in the current folder" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536

  # Act
  run bash -c 'cd "$1" && PATH="$2" sh "$3" game.nds' _ "${WORK}" "${PATH}" "${REPO_DIR}/bin/kirisute"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}
