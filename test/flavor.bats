#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/ks-flavor.XXXXXX")"
}

teardown() {
  rm -rf "${WORK}"
}

fake_tool() {
  local path="$1"
  local text="$2"
  mkdir -p "${path%/*}"
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nprintf "%%s\\n" "%s"\nexit 1\n' "${text}" >"${path}"
  chmod +x "${path}"
  printf '%s\n' "${path}"
}

flavor_of() {
  local tool
  tool="$(fake_tool "${WORK}/bin/$1" "$2")"
  KIRISUTE_OS="${3:-Darwin}" ks_test_call ks_tool_flavor "${tool}"
}

@test "GNU coreutils reads as gnu with its version" {
  # Arrange
  local text="mv (GNU coreutils) 9.5"

  # Act
  run flavor_of mv "${text}"

  # Assert
  [[ "${output}" == "gnu 9.5" ]]
}

@test "Ubuntu's GNU coreutils without the GNU word reads as gnu" {
  # Arrange
  local text="mv (coreutils) 9.7"

  # Act
  run flavor_of mv "${text}" Linux

  # Assert
  [[ "${output}" == "gnu 9.7" ]]
}

@test "uutils coreutils reads as uutils with its version" {
  # Arrange
  local text="mv (uutils coreutils) 0.12.0"

  # Act
  run flavor_of mv "${text}"

  # Assert
  [[ "${output}" == "uutils 0.12.0" ]]
}

@test "BusyBox reads as busybox" {
  # Arrange
  local text="BusyBox v1.36.1 (2024-06-10) multi-call binary."

  # Act
  run flavor_of mkdir "${text}" Linux

  # Assert
  [[ "${output}" == "busybox 1.36.1" ]]
}

@test "BusyBox that names itself after its error line reads as busybox" {
  # Arrange
  local text
  text="$(printf "awk: invalid option -- '-'\nBusyBox v1.37.0 (Ubuntu 1:1.37.0-7ubuntu1) multi-call binary.")"

  # Act
  run flavor_of awk "${text}" Linux

  # Assert
  [[ "${output}" == "busybox 1.37.0" ]]
}

@test "BusyBox sed, which says it is not GNU sed, reads as busybox" {
  # Arrange
  local text="This is not GNU sed version 4.0"

  # Act
  run flavor_of sed "${text}" Linux

  # Assert
  [[ "${output}" == "busybox" ]]
}

@test "a tool that refuses --version on macOS reads as bsd" {
  # Arrange
  local text="mv: illegal option -- -"

  # Act
  run flavor_of mv "${text}" Darwin

  # Assert
  [[ "${output}" == "bsd" ]]
}

@test "a tool that refuses --version on FreeBSD reads as bsd" {
  # Arrange
  local text="mv: illegal option -- -"

  # Act
  run flavor_of mv "${text}" FreeBSD

  # Assert
  [[ "${output}" == "bsd" ]]
}

@test "a tool that refuses --version on Linux reads as unknown" {
  # Arrange
  local text="usage: mv source target"

  # Act
  run flavor_of mv "${text}" Linux

  # Assert
  [[ "${output}" == "unknown" ]]
}

@test "a uutils tool that refuses --version is named by where it lives" {
  # Arrange
  local tool
  tool="$(fake_tool "${WORK}/uutils-coreutils/uubin/mv" "unrecognized option '--version'")"

  # Act
  KIRISUTE_OS=Darwin run ks_test_call ks_tool_flavor "${tool}"

  # Assert
  [[ "${output}" == "uutils" ]]
}

@test "the host system decides when KIRISUTE_OS is not set" {
  # Arrange
  local tool expected=unknown
  tool="$(fake_tool "${WORK}/bin/mv" "usage: mv source target")"
  [[ "$(uname -s || true)" != Darwin ]] || expected=bsd

  # Act
  run ks_test_call ks_tool_flavor "${tool}"

  # Assert
  [[ "${output}" == "${expected}" ]]
}
