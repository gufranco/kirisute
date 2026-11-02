#!/usr/bin/env bats

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  ks_test_setup
  ROM="${WORK}/game.nds"
  ks_test_rom "${ROM}" plain 16384 0 65536
}

teardown() {
  ks_test_teardown
}

from_folder() {
  local dir="$1"
  shift
  (cd "${dir}" && "$@")
}

help_options() {
  local page
  page="$(ks_test_run help)" || return 1
  awk '/^  --/ { for (i = 1; i <= NF; i++) if (match($i, /^--[a-z0-9][a-z0-9-]*/)) { name = substr($i, RSTART, RLENGTH); if (!seen[name]++) print name } }' <<<"${page}"
}

option_drift() {
  local option name man_form missing="" listed completed
  listed="$(help_options)" || return 1
  completed="$(grep -oE -- "--[a-z0-9][a-z0-9-]*" "${REPO_DIR}/completions/kirisute.bash")" || return 1
  for option in ${listed}; do
    name="${option#--}"
    man_form="\\-\\-${name//-/\\-}"
    grep -qF -- "${man_form}" "${REPO_DIR}/man/kirisute.1" || missing="${missing} man:${option}"
    grep -qE -- "(^|[ \"])${option}( |\"|$)" "${REPO_DIR}/completions/kirisute.bash" || missing="${missing} bash:${option}"
    grep -qE -- "[')\"]${option}\\[" "${REPO_DIR}/completions/_kirisute" || missing="${missing} zsh:${option}"
    grep -qE -- "-l ${name} " "${REPO_DIR}/completions/kirisute.fish" || missing="${missing} fish:${option}"
  done
  for option in ${completed}; do
    grep -qx -- "${option}" <<<"${listed}" || missing="${missing} help:${option}"
  done
  printf '%s' "${missing}"
}

@test "help prints the usage page" {
  # Arrange
  local first="kirisute - cut GBA, DS, DSi and 3DS ROM files down to their real size"

  # Act
  run ks_test_run help

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "${first}" ]]
  [[ "${output}" == *"examples:"* ]]
}

@test "-h and --help print the same page as help" {
  # Arrange
  local page
  page="$(ks_test_run help)"

  # Act
  run ks_test_run -h

  # Assert
  [[ "${output}" == "${page}" ]]
  run ks_test_run --help
  [[ "${output}" == "${page}" ]]
}

@test "version prints the program, its version and the platform" {
  # Arrange
  local version
  version="$(ks_test_version)"

  # Act
  run ks_test_run version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "kirisute ${version}" ]]
  [[ "${lines[1]}" == "platform: "* ]]
}

@test "version, -V and --version print the same lines" {
  # Arrange
  local page
  page="$(ks_test_run version)"

  # Act
  run ks_test_run -V

  # Assert
  [[ "${output}" == "${page}" ]]
  run ks_test_run --version
  [[ "${output}" == "${page}" ]]
}

@test "version reports an unknown platform when uname fails" {
  # Arrange
  ks_test_shim uname 'exit 1'

  # Act
  run ks_test_run version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "platform: unknown" ]]
}

@test "doctor lists every tool with its path" {
  # Arrange
  local tool

  # Act
  run ks_test_run doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  for tool in awk od head tail tr wc mktemp mv stat chmod rm; do
    [[ "${output}" == *"$(printf '%-18s %-8s ' "${tool}" ok)"/* ]]
  done
}

@test "doctor fails and names a missing tool" {
  # Arrange
  local farm
  farm="$(ks_test_farm mktemp)"

  # Act
  run ks_test_run_path "${farm}" doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"mktemp             missing  required, part of coreutils"* ]]
}

@test "the tool runs by its bare name from inside its own folder" {
  # Arrange
  local version
  local -a shell_words
  version="$(ks_test_version)"
  read -r -a shell_words <<<"${KIRISUTE_TEST_SHELL:-sh}"

  # Act
  run from_folder "${REPO_DIR}/bin" env PATH="${REPO_DIR}/bin:${PATH}" "${shell_words[@]}" kirisute version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "kirisute ${version}" ]]
}

@test "an unknown option is named with a hint" {
  # Arrange
  local expected="kirisute: unknown option '--fast'. run 'kirisute help' for usage."

  # Act
  run ks_test_run --fast "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "an unknown short option is named with a hint" {
  # Arrange
  local expected="kirisute: unknown option '-r'. run 'kirisute help' for usage."

  # Act
  run ks_test_run -r "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "a value given to a switch is refused" {
  # Arrange
  local expected="kirisute: unknown option '--verify'. run 'kirisute help' for usage."

  # Act
  run ks_test_run --verify=yes "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "an empty file name is refused before or after --" {
  # Arrange
  local expected="kirisute: the file name is empty. run 'kirisute help' for usage."

  # Act
  run ks_test_run ""

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
  run ks_test_run -- ""
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "-- ends the options so a ROM may start with a dash" {
  # Arrange
  ks_test_rom "${WORK}/-game.nds" plain 16384 0 65536

  # Act
  run from_folder "${WORK}" ks_test_run -- -game.nds

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${WORK}/-game.nds" 16384
}

@test "a ROM named like a command is reached by its path" {
  # Arrange
  ks_test_rom "${WORK}/help" plain 16384 0 65536

  # Act
  run ks_test_run "${WORK}/help"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${WORK}/help" 16384
}

@test "KIRISUTE_VERIFY and KIRISUTE_BACKUP set the defaults" {
  # Arrange
  ks_test_rom "${ROM}" plain 16384 0 65536 000

  # Act
  KIRISUTE_VERIFY=yes KIRISUTE_BACKUP=yes run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"        keep each original as <rom>.bak"$'\n'"        trim only a ROM whose padding is nothing but 00 or FF"* ]]
  ks_test_size_is "${ROM}.bak" 65536
}

@test "an option on the command line wins over the environment" {
  # Arrange
  local plan

  # Act
  KIRISUTE_VERIFY=yes KIRISUTE_BACKUP=yes run ks_test_run --no-verify --no-backup "${ROM}"

  # Assert
  [[ "${status}" -eq 0 ]]
  plan="$(printf '%s\n' "${output}" | grep -c '^        ' || true)"
  [[ "${plan}" -eq 0 ]]
  [[ ! -e "${ROM}.bak" ]]
}

@test "a setting from the environment must be yes or no" {
  # Arrange
  local verify="kirisute: KIRISUTE_VERIFY must be yes or no, got: maybe"
  local backup="kirisute: KIRISUTE_BACKUP must be yes or no, got: 1"

  # Act
  KIRISUTE_VERIFY=maybe run ks_test_run "${ROM}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${verify}" ]]
  KIRISUTE_BACKUP=1 run ks_test_run "${ROM}"
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${backup}" ]]
  ks_test_size_is "${ROM}" 65536
}

@test "without a ROM and a terminal the run stops with a hint" {
  # Arrange
  local expected="kirisute: no ROM file given. run 'kirisute help' for usage."

  # Act
  run ks_test_run --dry-run </dev/null

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "in a terminal the ROM is asked for" {
  # Arrange
  local answer="${ROM}"

  # Act
  KIRISUTE_INTERACTIVE=1 run ks_test_run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "ROM file or folder [.]: " ]]
  ks_test_size_is "${ROM}" 16384
}

@test "Enter at the prompt trims the current folder" {
  # Arrange
  local empty=""

  # Act
  KIRISUTE_INTERACTIVE=1 run from_folder "${WORK}" ks_test_run <<<"${empty}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
  [[ -z "${empty}" ]]
}

@test "a path typed with a tilde starts at home" {
  # Arrange
  # shellcheck disable=SC2088
  local answer="~/game.nds"

  # Act
  HOME="${WORK}" KIRISUTE_INTERACTIVE=1 run ks_test_run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "a lone tilde is home itself" {
  # Arrange
  local answer="~"

  # Act
  HOME="${WORK}" KIRISUTE_INTERACTIVE=1 run ks_test_run <<<"${answer}"

  # Assert
  [[ "${status}" -eq 0 ]]
  ks_test_size_is "${ROM}" 16384
}

@test "end of input at the prompt stops the run" {
  # Arrange
  local empty=""

  # Act
  KIRISUTE_INTERACTIVE=1 run ks_test_run < <(printf '%s' "${empty}")

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "ROM file or folder [.]: " ]]
  ks_test_size_is "${ROM}" 65536
}

@test "help, man page and completions list the same options" {
  # Arrange
  local expected=""

  # Act
  run option_drift

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "the man page passes mandoc lint" {
  # Arrange
  local page="${REPO_DIR}/man/kirisute.1"

  # Act
  run mandoc -T lint "${page}"

  # Assert
  [[ "${status}" -eq 0 ]]
}
