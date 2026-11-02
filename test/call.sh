#!/bin/sh
[ -n "${ZSH_VERSION:-}" ] && emulate sh

KS_LIB="$(cd "$(dirname "$0")/../lib" && pwd)" || exit 1

# shellcheck source=SCRIPTDIR/../lib/core.sh
. "${KS_LIB}/core.sh"
# shellcheck source=SCRIPTDIR/../lib/cli.sh
. "${KS_LIB}/cli.sh"
# shellcheck source=SCRIPTDIR/../lib/doctor.sh
. "${KS_LIB}/doctor.sh"
# shellcheck source=SCRIPTDIR/../lib/rom.sh
. "${KS_LIB}/rom.sh"
# shellcheck source=SCRIPTDIR/../lib/trim.sh
. "${KS_LIB}/trim.sh"

call_cleanup() {
  KS_TMP="$1"
  ks_cleanup
  ks_cleanup
}

"$@"
