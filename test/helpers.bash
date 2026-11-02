#!/usr/bin/env bash

KIRISUTE_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${KIRISUTE_TESTS_DIR}/.." && pwd)"
export KIRISUTE_TESTS_DIR REPO_DIR

ks_test_setup() {
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/ks.XXXXXX")"
  WORK="$(cd "${WORK}" && pwd -P)"
  export WORK
}

ks_test_teardown() {
  chmod -R u+rwx "${WORK}" 2>/dev/null || true
  rm -rf "${WORK:?}"
}

ks_test_path() {
  if [[ -n "${SHIMS:-}" && -d "${SHIMS}" ]]; then
    printf '%s:%s\n' "${SHIMS}" "${PATH}"
  else
    printf '%s\n' "${PATH}"
  fi
}

ks_test_shim() {
  local name="$1"
  local body="$2"
  local real
  SHIMS="${SHIMS:-${WORK:?}/shims}"
  mkdir -p "${SHIMS}"
  real="$(PATH="${PATH}" command -v "${name}" || true)"
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nREAL=%q\n%s\n' "${real}" "${body}" >"${SHIMS}/${name}.tmp"
  chmod +x "${SHIMS}/${name}.tmp"
  mv -f "${SHIMS}/${name}.tmp" "${SHIMS}/${name}"
  export SHIMS
}

ks_test_run() {
  local search_path
  local -a shell_words
  search_path="$(ks_test_path)"
  read -r -a shell_words <<<"${KIRISUTE_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${REPO_DIR}/bin/kirisute" "$@"
}

ks_test_run_path() {
  local search_path="$1"
  local -a shell_words
  shift
  read -r -a shell_words <<<"${KIRISUTE_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${REPO_DIR}/bin/kirisute" "$@"
}

ks_test_call() {
  local search_path
  local -a shell_words
  search_path="$(ks_test_path)"
  read -r -a shell_words <<<"${KIRISUTE_TEST_SHELL:-sh}"
  PATH="${search_path}" "${shell_words[@]}" "${KIRISUTE_TESTS_DIR}/call.sh" "$@"
}

ks_test_farm_wanted() {
  local farm="$1"
  local tool="$2"
  local name="${2##*/}"
  local excluded
  shift 2
  [[ -x "${tool}" && ! -e "${farm}/${name}" ]] || return 1
  for excluded in "$@"; do
    [[ "${name}" == "${excluded}" ]] && return 1
  done
  return 0
}

ks_test_farm() {
  local farm="${WORK:?}/farm"
  local dir tool
  local -a dirs batch
  mkdir -p "${farm}"
  IFS=: read -r -a dirs <<<"${PATH}"
  for dir in "${dirs[@]}"; do
    batch=()
    for tool in "${dir}"/*; do
      ks_test_farm_wanted "${farm}" "${tool}" "$@" && batch+=("${tool}")
    done
    [[ ${#batch[@]} -eq 0 ]] || ln -s "${batch[@]}" "${farm}/"
  done
  printf '%s\n' "${farm}"
}

ks_test_rom() {
  bash "${KIRISUTE_TESTS_DIR}/rom.bash" "$@"
}

ks_test_gba() {
  bash "${KIRISUTE_TESTS_DIR}/gba.bash" "$@"
}

ks_test_ctr() {
  bash "${KIRISUTE_TESTS_DIR}/ctr.bash" "$@"
}

ks_test_psp() {
  bash "${KIRISUTE_TESTS_DIR}/psp.bash" "$@"
}

ks_test_size_is() {
  local size
  size="$(wc -c <"$1")"
  [[ "${size//[[:space:]]/}" -eq "$2" ]]
}

ks_test_no_temporary() {
  local found
  found="$(find "$1" -name '.kirisute.*')"
  [[ -z "${found}" ]]
}

ks_test_version() {
  sed -n 's/^KIRISUTE_VERSION="\(.*\)"$/\1/p' "${REPO_DIR}/lib/core.sh"
}

ks_test_matches_golden() {
  local name="$1"
  local actual="$2"
  local os golden normalized
  os="$(uname -s)"
  golden="${KIRISUTE_TESTS_DIR}/golden/${name}.${os}.txt"
  normalized="${actual//"${WORK}"/WORK}"
  if [[ "${KIRISUTE_TEST_RECORD:-}" == "1" ]]; then
    mkdir -p "${KIRISUTE_TESTS_DIR}/golden"
    printf '%s\n' "${normalized}" >"${golden}.tmp"
    mv -f "${golden}.tmp" "${golden}"
  fi
  diff <(printf '%s\n' "${normalized}") "${golden}"
}
