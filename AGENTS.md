# kirisute

Guidance for anyone, human or agent, changing kirisute. What kirisute is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything kirisute shares with the rest of the kodougu family, and it is the same in every member. This file holds only what is exclusive to kirisute, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into `FAMILY.md` instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/kirisute`](bin/kirisute) | The entry point: it clears inherited `KS_` variables, sources the modules and dispatches the command |
| [`lib/`](lib) | The modules. [`lib/state.sh`](lib/state.sh) declares every global, including each system's constants; [`lib/rom.sh`](lib/rom.sh) picks a ROM's system and calls that system's functions, [`lib/nds.sh`](lib/nds.sh) is the Nintendo DS and DSi system, [`lib/trim.sh`](lib/trim.sh) writes and swaps the trimmed copy, [`lib/walk.sh`](lib/walk.sh) finds the ROMs and [`lib/process.sh`](lib/process.sh) decides what happens to each |
| [`man/kirisute.1`](man/kirisute.1) | The man page |
| [`completions/`](completions) | bash, zsh and fish completions |
| [`test/`](test) | The `bats` suite, its helpers, the ROM builder [`test/rom.bash`](test/rom.bash), the golden transcripts, the shell matrix runner and the Linux container script |
| [`scripts/`](scripts) | Coverage, the coverage gate, the Linux coverage run and the name check, which `make` runs |
| [`.github/scripts/`](.github/scripts) | The toolset helper and the release version stamp, which only CI and the release run |

## Names

- Globals carry `KS_`; function-scoped variables carry a per-function `ks_` prefix.
- Settings come from `KIRISUTE_VERIFY` and `KIRISUTE_BACKUP`; test switches are `KIRISUTE_TERMINAL`, `KIRISUTE_INTERACTIVE`, `KIRISUTE_OS`, `KIRISUTE_TEST_SHELLS`, `KIRISUTE_TEST_JOBS`, `KIRISUTE_TEST_RECORD` and `KIRISUTE_TEST_IMAGE`.
- Output goes through `ks_say`, `ks_error` and `ks_warning`.

## Behaviour

- kirisute has one job, so a bare `kirisute` on a terminal asks for a ROM file or folder directly, offering the current folder.
- Its options are `--dry-run`, `--info`, `--verify` and `--no-verify`, `--backup` and `--no-backup`, `--recursive` and `--json`, so the help page has a single `options:` section. `--json` reports the counts of ROMs found, read, trimmed, already trimmed, skipped and failed, the bytes saved, and one entry per file.
- Trimming drops only bytes past what the header declares, so it shows its summary block and starts without a typed confirmation, as shiwake does.
- A skipped or failed ROM makes the run end with status 1, and the other ROMs are still trimmed.

## Domain rules

- kirisute is meant to trim Game Boy Advance, Nintendo DS, DSi and 3DS images and PSP ISOs. Nintendo DS and DSi is the only system so far.
- A system lives in its own `lib/<system>.sh` and provides `ks_<system>_read`, which sets `KS_ROM_STATUS`, `KS_ROM_TITLE` and `KS_ROM_CODE` from one header read; `ks_<system>_reason`, which sets `KS_REASON` to the skip reason for a status other than `ok`, or empties it; `ks_<system>_target`, which sets `KS_ROM_TARGET` and `KS_ROM_KIND`; `ks_<system>_keeps`, the clause naming what a trim keeps; `ks_<system>_info`, its own `--info` lines; and `ks_<system>_json`, its own `--info` JSON fields. Its constants and fields in [`lib/state.sh`](lib/state.sh) carry `KS_<SYSTEM>_`.
- `ks_rom_system` in [`lib/rom.sh`](lib/rom.sh) maps a file extension to its system. A folder walk visits only files whose extension names a system; a file given by name with any other extension is read with `KS_SYSTEM_DEFAULT`.
- A system's trim rule comes from public format documentation such as GBATEK and 3dbrew. GodMode9 is a clean-room reference: its behaviour may be studied and restated as requirements, and its code is never copied or adapted.
- The trim sizes follow GodMode9: the NTR ROM size at `0x80`; that plus the 136-byte RSA certificate when the two bytes after it are `ac`; and the TWL size at `0x210` for a unit code other than 0.
- A ROM is accepted only when the CRC-16 of its logo area, 156 bytes from `0xC0`, is `0xCF56` and the CRC-16 of its first 350 bytes matches the value at `0x15E`. One `od` read of the first 544 bytes and one `awk` pass check both and read every field, so a ROM costs no extra process per field.
- The trimmed copy is written beside the ROM with `head -c`, checked against the expected size with `wc -c`, given the original's mode, then renamed over it. With `--backup` the original is renamed to `<rom>.bak` first and put back if the swap fails.
- Folders are walked with globs, never `find`, to a depth of `KS_DEPTH_MAX`; the walk keeps its state in positional parameters, since POSIX `sh` has no local variables and the walk recurses.
- Tests never commit a real ROM or Nintendo's logo bitmap: `test/rom.bash` builds ROMs around a 156-byte stand-in whose CRC-16 is `0xCF56`, and computes the header checksum itself.

## Release

- `KIRISUTE_VERSION` lives in [`lib/core.sh`](lib/core.sh).

## Gaps against FAMILY.md

None (as of 2026-11-02).
