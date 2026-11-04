#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/bin"
mkdir -p "${demo}/roms" "${demo}/psp"
bash "${SCREENS_REPO}/test/rom.bash" "${demo}/roms/adventure.nds" plain 3145728 0 16777216
bash "${SCREENS_REPO}/test/rom.bash" "${demo}/roms/puzzle.nds" plain 1048576 0 8388608
bash "${SCREENS_REPO}/test/rom.bash" "${demo}/roms/racer.nds" dsi 2097152 4194304 16777216
bash "${SCREENS_REPO}/test/psp.bash" "${demo}/psp/game.iso" 512 4194304
