#!/bin/sh
set -eu

version=${1:?version required}
root=$(cd "$(dirname "$0")/../.." && pwd)
core="${root}/lib/core.sh"

if ! grep -q '^KIRISUTE_VERSION=' "${core}"; then
  printf 'no KIRISUTE_VERSION assignment found in %s\n' "${core}" >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/kirisute-version-XXXXXX")
sed "s/^KIRISUTE_VERSION=\".*\"$/KIRISUTE_VERSION=\"${version}\"/" "${core}" >"${tmp}"
cat "${tmp}" >"${core}"
rm -f "${tmp}"

reported=$("${root}/bin/kirisute" --version)
printf 'version set to %s\n' "${reported}"
