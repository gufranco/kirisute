#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  LIB="${WORK}/library"
}

teardown() {
  ks_test_teardown
}

@test "a folder gives the .nds files directly inside it, in any case" {
  # Arrange
  ks_test_rom "${LIB}/a.nds" plain 16384 0 65536
  ks_test_rom "${LIB}/B.NDS" plain 16384 0 65536
  ks_test_rom "${LIB}/c.bin" plain 16384 0 65536
  ks_test_rom "${LIB}/sub/d.nds" plain 16384 0 65536

  # Act
  run ks_test_run "${LIB}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Files:  2 ROMs, 128.0 KiB"* ]]
  ks_test_size_is "${LIB}/a.nds" 16384
  ks_test_size_is "${LIB}/B.NDS" 16384
  ks_test_size_is "${LIB}/c.bin" 65536
  ks_test_size_is "${LIB}/sub/d.nds" 65536
}

@test "--recursive walks every subfolder" {
  # Arrange
  ks_test_rom "${LIB}/a.nds" plain 16384 0 65536
  ks_test_rom "${LIB}/sub/deeper/d.nds" plain 16384 0 65536

  # Act
  run ks_test_run --recursive "${LIB}/"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Trimmed 2 ROMs and saved 96.0 KiB." ]]
  ks_test_size_is "${LIB}/sub/deeper/d.nds" 16384
}

@test "hidden files and folders are left alone" {
  # Arrange
  ks_test_rom "${LIB}/._a.nds" plain 16384 0 65536
  ks_test_rom "${LIB}/.hidden/b.nds" plain 16384 0 65536

  # Act
  run ks_test_run --recursive "${LIB}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No ROM to trim." ]]
  ks_test_size_is "${LIB}/._a.nds" 65536
}

@test "symbolic links inside a folder are left alone" {
  # Arrange
  ks_test_rom "${WORK}/real/a.nds" plain 16384 0 65536
  mkdir -p "${LIB}"
  ln -s "${WORK}/real/a.nds" "${LIB}/a.nds"
  ln -s "${WORK}/real" "${LIB}/loop"

  # Act
  run ks_test_run --recursive "${LIB}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No ROM to trim." ]]
  ks_test_size_is "${WORK}/real/a.nds" 65536
}

@test "a symbolic link given by name is refused" {
  # Arrange
  ks_test_rom "${WORK}/real.nds" plain 16384 0 65536
  ln -s "${WORK}/real.nds" "${WORK}/link.nds"

  # Act
  run ks_test_run "${WORK}/link.nds"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kirisute: ${WORK}/link.nds is a symbolic link, so it stays as it is. give the file it points to."$'\n'"No ROM to trim." ]]
}

@test "a missing file is named and the other ROMs are still trimmed" {
  # Arrange
  ks_test_rom "${LIB}/a.nds" plain 16384 0 65536

  # Act
  run ks_test_run "${WORK}/gone.nds" "${LIB}/a.nds"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${lines[0]}" == "kirisute: no such file or folder: ${WORK}/gone.nds" ]]
  ks_test_size_is "${LIB}/a.nds" 16384
}

@test "a special file is refused" {
  # Arrange
  mkfifo "${WORK}/pipe.nds"

  # Act
  run ks_test_run "${WORK}/pipe.nds"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${lines[0]}" == "kirisute: ${WORK}/pipe.nds is not a regular file, so it stays as it is." ]]
}

@test "an empty folder has no ROM to trim" {
  # Arrange
  mkdir -p "${LIB}"

  # Act
  run ks_test_run "${LIB}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "No ROM to trim." ]]
}

@test "a folder deeper than the limit is not looked inside" {
  # Arrange
  local dir="${LIB}"
  local level
  for ((level = 0; level < 33; level++)); do
    dir="${dir}/d"
  done
  ks_test_rom "${dir}/deep.nds" plain 16384 0 65536
  ks_test_rom "${LIB}/top.nds" plain 16384 0 65536

  # Act
  run ks_test_run --recursive "${LIB}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"is more than 32 folders deep, so kirisute does not look inside it."* ]]
  ks_test_size_is "${dir}/deep.nds" 65536
  ks_test_size_is "${LIB}/top.nds" 16384
}

@test "a name with spaces, brackets and a newline passes intact" {
  # Arrange
  local name
  name="$(printf 'odd [name]\nhere.nds')"
  ks_test_rom "${LIB}/${name}" plain 16384 0 65536

  # Act
  run ks_test_run "${LIB}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${LIB}/${name}" 16384
}
