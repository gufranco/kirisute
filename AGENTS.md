# kirisute

Guidance for anyone, human or agent, changing kirisute. What kirisute is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything kirisute shares with the rest of the kodougu family, and it is the same in every member. This file holds only what is exclusive to kirisute, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into `FAMILY.md` instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bin/kirisute`](bin/kirisute) | The entry point: it clears inherited `KS_` variables, sources the modules and dispatches the command |
| [`lib/`](lib) | The modules. [`lib/state.sh`](lib/state.sh) declares every global, including the header offsets' constants; [`lib/rom.sh`](lib/rom.sh) reads a header, [`lib/trim.sh`](lib/trim.sh) writes and swaps the trimmed copy, [`lib/walk.sh`](lib/walk.sh) finds the ROMs and [`lib/process.sh`](lib/process.sh) decides what happens to each |
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

- The trim sizes follow GodMode9: the NTR ROM size at `0x80`; that plus the 136-byte RSA certificate when the two bytes after it are `ac`; and the TWL size at `0x210` for a unit code other than 0.
- A ROM is accepted only when the CRC-16 of its logo area, 156 bytes from `0xC0`, is `0xCF56` and the CRC-16 of its first 350 bytes matches the value at `0x15E`. One `od` read of the first 544 bytes and one `awk` pass check both and read every field, so a ROM costs no extra process per field.
- The trimmed copy is written beside the ROM with `head -c`, checked against the expected size with `wc -c`, given the original's mode, then renamed over it. With `--backup` the original is renamed to `<rom>.bak` first and put back if the swap fails.
- Folders are walked with globs, never `find`, to a depth of `KS_DEPTH_MAX`; the walk keeps its state in positional parameters, since POSIX `sh` has no local variables and the walk recurses.
- Tests never commit a real ROM or Nintendo's logo bitmap: `test/rom.bash` builds ROMs around a 156-byte stand-in whose CRC-16 is `0xCF56`, and computes the header checksum itself.

## Release

- `KIRISUTE_VERSION` lives in [`lib/core.sh`](lib/core.sh).

## Gaps against FAMILY.md

None (as of 2026-11-02).
