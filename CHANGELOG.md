# Changelog

# [2.0.0](https://github.com/gufranco/kirisute/compare/v1.2.1...v2.0.0) (2026-11-11)


### Bug Fixes

* read file sizes past 4 GiB under BusyBox ([91a81d7](https://github.com/gufranco/kirisute/commit/91a81d726e5bdaa76affd7f08390d3a658bc1a5b))
* size a file whose name starts with a dash ([da622c5](https://github.com/gufranco/kirisute/commit/da622c591596304ad7d2b1698181331b216a1142))


### Features

* keep each original by default ([9d04efd](https://github.com/gufranco/kirisute/commit/9d04efdbb52aad39a32205bb9959e117c77916da))


### BREAKING CHANGES

* trimming without --backup now leaves ROM.bak beside
each trimmed ROM; pass --no-backup or set KIRISUTE_BACKUP=no for the
old behaviour.

## [1.2.1](https://github.com/gufranco/kirisute/compare/v1.2.0...v1.2.1) (2026-11-04)


### Bug Fixes

* let the terminal wrap long messages ([e6b2803](https://github.com/gufranco/kirisute/commit/e6b28035e9f78a5ec3d29d101292b85996eb3352))
* **ui:** line up table cells with wide letters ([7bdf2ef](https://github.com/gufranco/kirisute/commit/7bdf2ef4549418b6c8c318c9467ad34e843a7c8e))

# [1.2.0](https://github.com/gufranco/kirisute/compare/v1.1.0...v1.2.0) (2026-11-04)


### Features

* draw the terminal interface with gum ([12937f3](https://github.com/gufranco/kirisute/commit/12937f3887f1074fa2188e6c911a5b995eaa5909))

# [1.1.0](https://github.com/gufranco/kirisute/compare/v1.0.0...v1.1.0) (2026-11-02)


### Bug Fixes

* **ci:** build maxcso against Homebrew libraries ([6383436](https://github.com/gufranco/kirisute/commit/638343681747d0fa470322e2175c98167c0cfb8e))
* **ci:** gate every lib module's coverage ([cbf733f](https://github.com/gufranco/kirisute/commit/cbf733f4ff81d77d4b208e27b03e150c8e5199a4))
* keep data past a PSP disc's declared volume ([2866b34](https://github.com/gufranco/kirisute/commit/2866b34167bd1db4933df54b2b6046f0f8040a60))


### Features

* compress PSP disc images for ARK ([918e4e9](https://github.com/gufranco/kirisute/commit/918e4e908512b65ce40c8bc14263e630c70147c9))
* rename ROMs after their headers ([f21636f](https://github.com/gufranco/kirisute/commit/f21636ff0e447f5cf402892b993cd5c70823bc32))
* trim 3DS cartridge images and executables ([f6f3930](https://github.com/gufranco/kirisute/commit/f6f393074b7fda9ff20e728a4876c4b9cda175a2))
* trim Game Boy Advance ROMs ([8ac9c20](https://github.com/gufranco/kirisute/commit/8ac9c208edfbca1d1606b4380482e7e0cdde86e4))
* trim PSP disc images ([15f269e](https://github.com/gufranco/kirisute/commit/15f269ee08c6817dd18d7ff33bc17853cd9b0421))

# 1.0.0 (2026-11-02)


### Features

* trim Nintendo DS and DSi ROMs ([df21450](https://github.com/gufranco/kirisute/commit/df214508395dbd55397432178d47815beb3918d0))
