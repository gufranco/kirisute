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
# shellcheck source=SCRIPTDIR/../lib/nds.sh
. "${KS_LIB}/nds.sh"
# shellcheck source=SCRIPTDIR/../lib/gba.sh
. "${KS_LIB}/gba.sh"
# shellcheck source=SCRIPTDIR/../lib/3ds.sh
. "${KS_LIB}/3ds.sh"
# shellcheck source=SCRIPTDIR/../lib/cxi.sh
. "${KS_LIB}/cxi.sh"
# shellcheck source=SCRIPTDIR/../lib/psp.sh
. "${KS_LIB}/psp.sh"
# shellcheck source=SCRIPTDIR/../lib/trim.sh
. "${KS_LIB}/trim.sh"
# shellcheck source=SCRIPTDIR/../lib/rename.sh
. "${KS_LIB}/rename.sh"

call_cleanup() {
  KS_TMP="$1"
  ks_cleanup
  ks_cleanup
}

"$@"
