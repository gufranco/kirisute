# kirisute

Guidance for anyone, human or agent, changing kirisute. What kirisute is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything kirisute shares with the rest of the kodougu family, and it is the same in every member. This file holds only what is exclusive to kirisute, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into `FAMILY.md` instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/kirisute`](bin/kirisute) | The entry point: it clears inherited `KS_` variables, sources the modules and dispatches the command |
| [`lib/`](lib) | The modules. [`lib/state.sh`](lib/state.sh) declares every global, including each system's constants; [`lib/rom.sh`](lib/rom.sh) picks a ROM's system and calls that system's functions, [`lib/nds.sh`](lib/nds.sh) is the Nintendo DS and DSi system, [`lib/gba.sh`](lib/gba.sh) the Game Boy Advance one, [`lib/3ds.sh`](lib/3ds.sh) the 3DS cartridge image one, [`lib/cxi.sh`](lib/cxi.sh) the 3DS executable one and [`lib/psp.sh`](lib/psp.sh) the PSP ISO one, [`lib/trim.sh`](lib/trim.sh) writes and swaps the trimmed copy, [`lib/walk.sh`](lib/walk.sh) finds the ROMs, [`lib/process.sh`](lib/process.sh) decides what happens to each and [`lib/rename.sh`](lib/rename.sh) holds the `rename` command |
| [`man/kirisute.1`](man/kirisute.1) | The man page |
| [`completions/`](completions) | bash, zsh and fish completions |
| [`test/`](test) | The `bats` suite, its helpers, the byte helpers [`test/bytes.bash`](test/bytes.bash) and one ROM builder per system, such as [`test/rom.bash`](test/rom.bash) for DS, [`test/gba.bash`](test/gba.bash), [`test/ctr.bash`](test/ctr.bash) for 3DS and [`test/psp.bash`](test/psp.bash), the golden transcripts, the shell matrix runner and the Linux container script |
| [`scripts/`](scripts) | Coverage, the coverage gate, the Linux coverage run and the name check, which `make` runs |
| [`.github/scripts/`](.github/scripts) | The toolset helper and the release version stamp, which only CI and the release run |

## Names

- Globals carry `KS_`; function-scoped variables carry a per-function `ks_` prefix.
- Settings come from `KIRISUTE_VERIFY` and `KIRISUTE_BACKUP`; test switches are `KIRISUTE_TERMINAL`, `KIRISUTE_INTERACTIVE`, `KIRISUTE_OS`, `KIRISUTE_TEST_SHELLS`, `KIRISUTE_TEST_JOBS`, `KIRISUTE_TEST_RECORD` and `KIRISUTE_TEST_IMAGE`.
- Output goes through `ks_say`, `ks_error` and `ks_warning`.

## Behaviour

- Trimming is the default job, so a bare `kirisute` on a terminal asks for a ROM file or folder directly, offering the current folder, as does a bare `kirisute rename`.
- `kirisute rename` names each ROM `<title> (<code>).<ext>` from its header, or `<code>.<ext>` when the header has no title. It takes `--dry-run`, `--recursive` and `--json`, and refuses `--info`, `--verify` and `--backup` with the usage hint. It never takes a name another file has, and a rename that only changes letter case goes through a temporary name, since the Mac's disk ignores case. Its JSON report counts `renamed` instead of `trimmed`, drops `info`, `read` and `saved`, and gives each file its `new_name`.
- Its options are `--dry-run`, `--info`, `--verify` and `--no-verify`, `--backup` and `--no-backup`, `--recursive` and `--json`, so the help page has a single `options:` section. `--json` reports the counts of ROMs found, read, trimmed, already trimmed, skipped and failed, the bytes saved, and one entry per file.
- Trimming drops only bytes past what the header declares, so it shows its summary block and starts without a typed confirmation, as shiwake does.
- A skipped or failed ROM makes the run end with status 1, and the other ROMs are still trimmed.

## Domain rules

- kirisute trims Game Boy Advance, Nintendo DS and DSi ROMs, 3DS cartridge images and executables, and PSP ISOs.
- A system lives in its own `lib/<system>.sh` and provides `ks_<system>_read`, which sets `KS_ROM_STATUS`, `KS_ROM_TITLE` and `KS_ROM_CODE` from one header read; `ks_<system>_reason`, which sets `KS_REASON` to the skip reason for a status other than `ok`, or empties it; `ks_<system>_target`, which sets `KS_ROM_TARGET` and `KS_ROM_KIND`; `ks_<system>_keeps`, the clause naming what a trim keeps; `ks_<system>_info`, its own `--info` lines; and `ks_<system>_json`, its own `--info` JSON fields. Its constants and fields in [`lib/state.sh`](lib/state.sh) carry `KS_<SYSTEM>_`.
- `ks_rom_system` in [`lib/rom.sh`](lib/rom.sh) maps a file extension to its system. A folder walk visits only files whose extension names a system; a file given by name with any other extension is read with `KS_SYSTEM_DEFAULT`.
- A system's trim rule comes from public format documentation such as GBATEK and 3dbrew. GodMode9 is a clean-room reference: its behaviour may be studied and restated as requirements, and its code is never copied or adapted.
- The trim sizes follow GodMode9: the NTR ROM size at `0x80`; that plus the 136-byte RSA certificate when the two bytes after it are `ac`; and the TWL size at `0x210` for a unit code other than 0.
- A DS ROM is accepted only when the CRC-16 of its logo area, 156 bytes from `0xC0`, is `0xCF56` and the CRC-16 of its first 350 bytes matches the value at `0x15E`. One `od` read of the first 544 bytes and one `awk` pass check both and read every field, so a ROM costs no extra process per field. The `awk` helpers every system shares, the CRC-16 among them, live in `ks_rom_awk_functions`.
- A Game Boy Advance ROM carries the same logo as a DS ROM, at `0x04`, so it is accepted when that logo's CRC-16 is `0xCF56`, the byte at `0xB2` is `0x96`, and the byte at `0xBD` equals 0 minus `0x19` minus the sum of `0xA0` to `0xBC`, modulo 256. Its header declares no size: when its last byte is 00 or FF, it is cut after the last byte that differs, rounded up to a multiple of 4, and left alone when that saves under 512 bytes. The scan reads 1 MiB blocks backwards with `tail` and `head`, counts what `tr -d` leaves, and runs `od` only on the block that holds the last data byte.
- A 3DS cartridge image, `.3ds` or `.cci`, follows 3dbrew's NCSD header: the magic `NCSD` at `0x100`, the image size in media units at `0x104`, the media ID at `0x108`, partition file-system types at `0x110`, and eight offset and size pairs at `0x120`. The media unit is 512 bytes doubled as many times as the flag byte at `0x18E` says. It is cut at the largest partition end, and refused when the magic is wrong, a file-system type is set, which marks a console NAND image, the media ID is zero, the first partition is empty, a partition starts before the previous one ends, or the partitions end past the declared size. Its product code is read from the NCCH header of the first partition, at `0x150` within it, and it has no title.
- A 3DS executable, `.cxi`, follows 3dbrew's NCCH header: the magic `NCCH` at `0x100`, its size in 512-byte units at `0x104`, the program ID at `0x118` and the product code at `0x150`. It is cut to its declared size.
- A PSP ISO, `.iso`, follows ECMA-119: the primary volume descriptor at byte 32768 holds type 1 and `CD001`, the volume identifier at 40, the volume space size at 80 and the logical block size at 128, both little-endian first, and the root directory record at 156. It is cut to the volume space size times the block size, and only when every byte past that is 00 or FF, whatever `--verify` says: reference dumps are sized by the UMD drive's last sector rather than by the volume, and a game can read sectors by number, so data past the volume is never provably padding. A PSP disc is told from any other ISO by the system identifier `PSP GAME`, also written with quotes, `UMD VIDEO` or `UMD AUDIO`, or by a `PSP_GAME` directory in the root, which covers homebrew. A development DVD-R image, whose root holds `USER_L0.IMG`, is refused with how to join its layers. Nothing inside the volume is ever removed or emptied: update data, dummy padding files and videos stay, since stripping them is lossy and breaks some games. Its title and disc ID come from the `TITLE` and `DISC_ID` keys of `PSP_GAME/PARAM.SFO`, a PSF file with little-endian key and data table offsets at 8 and 12, an entry count at 16 and 16-byte entries from 20. Directory scans skip to the next block at a zero-length record, read at most `KS_PSP_READ_MAX` bytes, and the PSF loop stops at `KS_PSP_SFO_ENTRIES` entries.
- The trimmed copy is written beside the ROM with `head -c`, checked against the expected size with `wc -c`, given the original's mode, then renamed over it. With `--backup` the original is renamed to `<rom>.bak` first and put back if the swap fails.
- Folders are walked with globs, never `find`, to a depth of `KS_DEPTH_MAX`; the walk keeps its state in positional parameters, since POSIX `sh` has no local variables and the walk recurses.
- Tests never commit a real ROM or Nintendo's logo bitmap: the builders put a 156-byte stand-in whose CRC-16 is `0xCF56` where the logo goes, and compute each header checksum themselves.

## Release

- `KIRISUTE_VERSION` lives in [`lib/core.sh`](lib/core.sh).

## Gaps against FAMILY.md

None (as of 2026-11-02).
