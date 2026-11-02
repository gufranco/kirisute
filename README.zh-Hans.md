<div align="center">

<h1>kirisute</h1>

<strong>把 Game Boy Advance、DS、DSi 和 3DS 的 ROM 以及 PSP 的 ISO 裁到真实大小，并按头部信息命名。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速开始</strong></a> |
  <a href="#what-is-kept">保留什么</a> |
  <a href="#rename">重命名</a> |
  <a href="#compress">压缩</a> |
  <a href="#development">开发</a>
</p>

</div>

卡带的转储和原来的芯片一样大，光盘镜像也可能在最后一个扇区之后带着填充。`kirisute` 是日语的「切り捨て」，意思是舍去余下的部分：它读取每个文件的头部，去掉数据之后的内容，所以一个 24 MiB 游戏的 64 MiB 转储在烧录卡的存储卡上只占 24 MiB。

---

```console
$ kirisute --backup download-play.nds advance.gba cartridge.3ds umd.iso notes.nds

Files:  5 ROMs, 304.1 MiB
Plan:   cut each ROM to the size its header declares
        keep each original as <rom>.bak

Trimmed download-play.nds from 32.0 MiB to 8.0 MiB, keeping its download-play
certificate.
Trimmed advance.gba from 16.0 MiB to 6.0 MiB.
Trimmed cartridge.3ds from 128.0 MiB to 42.0 MiB.
Trimmed umd.iso from 128.0 MiB to 100.0 MiB.
kirisute: warning: notes.nds has a bad logo checksum and is not a DS ROM, so it
stays as it is.
Trimmed 4 of 5 ROMs and saved 148.0 MiB.
```

<a id="quick-start"></a>

## 快速开始

### 前置条件

| 工具 | 用途 | 安装 |
|:-----|:-----|:-----|
| `awk`、`od`、`head`、`tail`、`tr`、`wc` | 读取头部并复制 ROM 的数据 | Linux 和 macOS 已预装 |
| `mktemp`、`mv`、`stat`、`chmod`、`rm` | 在 ROM 旁边写入裁剪后的副本并替换 | Linux 和 macOS 已预装 |
| `cmp` | 检查压缩副本能否解压回原文件 | Linux 和 macOS 已预装 |
| [maxcso](https://github.com/unknownbrackets/maxcso) | 为 `compress` 写出 CSO 和 ZSO 副本 | `brew install gufranco/tap/maxcso`；Homebrew formula 会一并安装 |

### 安装

```bash
brew install gufranco/tap/kirisute
```

也可以从源码安装：

```bash
git clone https://github.com/gufranco/kirisute.git
cd kirisute
make install
```

`make install` 会把工具、man 手册以及 bash、zsh 和 fish 的补全复制到 `~/.local`，并把 `kirisute` 放进 `~/.local/bin`；设置 `PREFIX` 可以改变位置。Homebrew formula 安装同样的文件。

### 验证

```console
$ kirisute doctor
awk                ok       /opt/homebrew/opt/gawk/libexec/gnubin/awk, gnu 5.4.1
od                 ok       /usr/bin/od, bsd
head               ok       /usr/bin/head, bsd
tail               ok       /usr/bin/tail, bsd
tr                 ok       /usr/bin/tr, bsd
wc                 ok       /usr/bin/wc, bsd
mktemp             ok       /usr/bin/mktemp, bsd
mv                 ok       /bin/mv, bsd
stat               ok       /usr/bin/stat, bsd
chmod              ok       /bin/chmod, bsd
rm                 ok       /bin/rm, bsd
cmp                ok       /opt/homebrew/bin/cmp, gnu 3.12
maxcso             ok       /opt/homebrew/bin/maxcso, 1.13.0
```

## 用法

| 命令 | 用途 |
|:-----|:-----|
| `kirisute [options] <rom>...` | 裁剪每个 ROM 文件，以及所给文件夹中的 ROM 文件 |
| `kirisute rename [options] <rom>...` | 按头部中的标题和代码重命名每个 ROM |
| `kirisute compress [options] <iso>...` | 为 ARK-4 和 ARK-5 写出每个 PSP 光盘镜像的 CSO 或 ZSO 副本 |
| 不带参数的 `kirisute` | 在终端中运行时询问 ROM 文件或文件夹，默认为当前文件夹 |
| `kirisute doctor` | 列出所需的工具及各自的种类与版本 |
| `kirisute version`、`kirisute help` | 显示版本或完整的用法说明 |

| 选项 | 作用 |
|:-----|:-----|
| `--dry-run` | 列出会裁剪或重命名的内容，不做任何改动 |
| `--info` | 显示每个 ROM 的头部：标题、代码、各系统特有的字段、裁剪后大小和填充 |
| `--verify`、`--no-verify` | 只裁剪填充全是 `00` 或 `FF` 字节的 ROM |
| `--backup`、`--no-backup` | 把每个原文件保留为 `<rom>.bak` |
| `--recursive` | 也在所有子文件夹中查找 ROM 文件 |
| `--json` | 把结果输出为一个 JSON 对象，供脚本使用 |

`KIRISUTE_VERIFY=yes` 和 `KIRISUTE_BACKUP=yes` 会让 `--verify` 和 `--backup` 成为默认；命令行上的选项优先。kirisute 遵循家族共享的命令行约定，内容见 [FAMILY.md](FAMILY.md)。

```bash
kirisute --dry-run *.nds *.3ds           # 看看裁剪能省多少
kirisute --backup --verify game.nds      # 保留原文件，填充中有数据时拒绝
kirisute --recursive ~/roms              # 裁剪整个游戏库
kirisute rename --dry-run *.gba          # 看看每个 ROM 会取什么名字
kirisute compress game.iso               # 为 ARK-4 和 ARK-5 写出 game.cso
```

<a id="what-is-kept"></a>

## 保留什么

| 文件 | 扩展名 | 裁剪到 |
|:-----|:-------|:-------|
| DS | `.nds` | 头部偏移 `0x80` 处的 ROM 大小 |
| 带下载游戏的 DS | `.nds` | 该大小加上其后 136 字节的 RSA 证书 |
| DSi 增强或 DSi 专用 | `.nds` | 头部偏移 `0x210` 处的 DSi 区域大小 |
| Game Boy Advance | `.gba` | 最后一个非填充字节，向上取整到 4 字节，且只在能省下至少 512 字节时裁剪 |
| 3DS 卡带镜像 | `.3ds`、`.cci` | 最后一个分区的结尾，按头部设定的媒体单位计算 |
| 3DS 可执行文件 | `.cxi` | NCCH 头部声明的大小 |
| PSP 光盘镜像 | `.iso` | ISO 9660 卷描述符声明的卷，且只在其后全是 `00` 或 `FF` 时裁剪 |

- 每个文件在处理前都会检查。DS 和 Game Boy Advance 的 ROM 需要正确的标志和头部校验和；3DS 镜像需要 NCSD 魔数、媒体 ID 和顺序正确的分区，主机 NAND 镜像会被拒绝；PSP 镜像需要系统名 `PSP GAME`、`UMD VIDEO` 或 `UMD AUDIO`，或者 `PSP_GAME` 文件夹。检查不通过、小到放不下头部、或头部声明的大小超过文件本身的文件会保持原样并给出警告，运行以状态 1 结束。
- 不加 `--verify` 时，真实大小之后的字节不论内容都会被去掉。加上后，那里只要有 `00` 和 `FF` 以外的字节，该 ROM 就保持原样，警告会指出第一个这样的字节。
- PSP 镜像总会做这项检查。转储工具按光盘的最后一个扇区而不是文件系统来决定镜像大小，游戏也能读取文件之外的扇区，所以 kirisute 绝不裁掉无法证明是填充的数据。卷内的内容也绝不删除：更新数据、填充文件和视频都会保留。含有 `USER_L0.IMG` 和 `USER_L1.IMG` 的开发用 DVD-R 镜像会被拒绝，直到把两层拼接起来。
- 裁剪后的文件不再与 Redump 或 No-Intro 等数据库中未裁剪转储的校验和一致。`--backup` 可以保留原文件。
- 每个裁剪后的 ROM 先写入旁边的临时文件，赋予原文件的权限，再重命名覆盖原文件，所以中断的运行不会留下写了一半的文件。
- 文件夹只提供其中直接包含的上述扩展名的文件，不分大小写；`--recursive` 最多深入 32 层文件夹。按名称给出的其他扩展名的文件会当作 DS ROM 读取。符号链接、`._game.nds` 这样的隐藏文件和隐藏文件夹都不会被处理。

<a id="rename"></a>

## 重命名

`kirisute rename` 按头部信息给每个 ROM 命名，让一文件夹的转储读起来像一份目录：

```console
$ kirisute rename --dry-run download-play.nds advance.gba cartridge.3ds umd.iso

Files:  4 ROMs, 156.0 MiB
Plan:   rename each ROM after the title and code in its header
        dry run: list each new name and change nothing

Would rename download-play.nds to KIRISUTE (KSTE).nds.
Would rename advance.gba to KIRISUTE GBA (AKSE).gba.
Would rename cartridge.3ds to CTR-P-AKSE.3ds.
Would rename umd.iso to Kirisute Test (ULUS99999).iso.
Dry run: 4 ROMs would be renamed. Nothing was changed.
```

- 名字是 `<标题> (<代码>)`；像 3DS 镜像那样头部没有标题时，只用代码。PSP 镜像的标题和光盘 ID 取自 `PSP_GAME/PARAM.SFO`。
- 扩展名保持小写。标题中的斜杠和冒号会变成连字符，控制字符会被去掉。
- 绝不会占用其他文件已有的名字：那个 ROM 会保持原样并给出警告。只改变大小写的重命名在 Mac 的磁盘上也能完成。
- `rename` 接受 `--dry-run`、`--recursive` 和 `--json`。

<a id="compress"></a>

## 压缩

`kirisute compress` 用 [maxcso](https://github.com/unknownbrackets/maxcso) 为每个 PSP 光盘镜像写出压缩副本，格式可被自制固件 ARK-4 和 ARK-5 读取，并保留原文件：

```console
$ kirisute compress --dry-run umd.iso

Files:  1 ROM, 100.0 MiB
Plan:   compress each PSP disc image to CSO v2 in 8 KiB blocks
        use LZ4 only where it is smaller than deflate
        keep each original and check that each copy decompresses to it
        dry run: list each copy and change nothing

Would compress umd.iso to umd.cso as CSO v2.
Dry run: 1 ROM would be compressed. Nothing was changed.
```

| 选项 | 作用 | 默认 |
|:-----|:-----|:-----|
| `--format cso` | CSO v1：只用 deflate，较旧的固件也能读取，三者中加载最慢 | |
| `--format cso2` | CSO v2：每个块选用 deflate 或 LZ4，体积小，读取也较快 | 是 |
| `--format zso` | ZSO：只用 LZ4，读取最快，文件较大 | |
| `--block N` | 块大小：2048、4096、8192 或 16384 字节。块越大压缩得稍好一些 | 8192 |
| `--lz4-cost N` | 对 CSO v2，当 LZ4 最多多占 N% 空间时就用 LZ4，以空间换读取速度；0 表示只在 LZ4 更小时使用 | 0 |
| `--best` | 多加一次慢速尝试：CSO v1 和 v2 用 Zopfli，ZSO 用暴力 LZ4。副本略小，但生成慢得多 | 关 |

`KIRISUTE_FORMAT`、`KIRISUTE_BLOCK`、`KIRISUTE_LZ4_COST` 和 `KIRISUTE_BEST` 可设置同样的默认值。

- 副本命名为 `game.cso` 或 `game.zso`，即 ARK 会列出的扩展名。CSO v2 文件也是 `.cso`；`.cso2` 的名字不会在主机上显示。
- 副本只有在逐字节解压回原文件后才会保留，检查期间需要与镜像同样大小的可用空间。已有的副本绝不会被覆盖。
- 不写出 DAX 和 JSO。maxcso 的 DAX 块缺少 ARK 预期的 zlib 头，而开源的 JSO 写入工具并不存在。ZSO 能提供 JSO 的快速读取。
- 默认设置写出的字节与 `maxcso --format=cso2 --block=8192 --use-zlib --use-7zdeflate --use-lz4 --use-lz4brute` 完全相同，其副本能在 ARK-4 和 ARK-5 上启动。更大的 `--lz4-cost`、`--best`、CSO v1 和 ZSO 是 ARK 读取器能解码的格式，但尚未在主机上试过。
- 想去掉填充就先裁剪；压缩本身也几乎不为连续的零占空间。

## 可移植性

全部使用 POSIX `sh` 编写，ShellCheck `-o all` 零警告。测试在 macOS 上于 `/bin/sh`、`dash`、系统自带的 bash 3.2 和 zsh、Homebrew 最新的 bash 和 zsh 下运行，在 Ubuntu 上于 `dash`、`bash`、`bash --posix` 和 `zsh` 下运行。CI 会在家族的六种工具集上重复这些测试：Linux 的 uutils、GNU 或 BusyBox 工具，以及 macOS 自带的工具、Homebrew 的较新版本或 Homebrew 的 uutils 工具。`kirisute doctor` 会写出每个工具的种类与版本，让错误报告说明运行的是哪些工具。

<a id="development"></a>

## 开发

| 命令 | 说明 |
|:-----|:-----|
| `make fmt` | 用 shfmt 格式化所有脚本 |
| `make lint` | shfmt、对所有脚本、测试和补全运行 ShellCheck、名称检查，以及对 man 手册运行 mandoc |
| `make test` | 在系统 `sh` 下运行 `bats` 测试 |
| `make test-all` | 在每种 shell 下运行同样的测试，macOS 上包括 bash 和 zsh 的两个版本 |
| `make test-linux` | 在 Ubuntu 容器中运行同样的测试 |
| `make coverage` | 合并本机与 Ubuntu 容器中的 bashcov 行覆盖率，并执行与 CI 相同的 100% 门槛 |

测试裁剪的是真实文件。每个系统都有一个生成器，写出头部和校验和都正确的文件：DS 用 [`test/rom.bash`](test/rom.bash)，另有 [`test/gba.bash`](test/gba.bash)、3DS 用 [`test/ctr.bash`](test/ctr.bash) 和 [`test/psp.bash`](test/psp.bash)。标志图像用替代数据，所以仓库中没有任天堂或索尼的数据。只有失败是注入的，通过 `PATH` 上的小包装脚本实现。推送到 `main` 且 CI 通过后，semantic-release 会运行：`feat` 或 `fix` 提交会发布新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `KIRISUTE_VERSION` 和 CHANGELOG，并更新 Homebrew formula。

## 许可证

[MIT](LICENSE)
