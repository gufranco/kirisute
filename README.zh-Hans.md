<div align="center">

<h1>kirisute</h1>

<strong>把任天堂 DS 和 DSi 的 ROM 文件裁到真实大小，保留头部声明的全部内容。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速开始</strong></a> |
  <a href="#what-is-kept">保留什么</a> |
  <a href="#development">开发</a>
</p>

</div>

DS 卡带的转储和原来的芯片一样大，文件末尾是填充。`kirisute` 是日语的「切り捨て」，意思是舍去余下的部分：它读取每个 ROM 的头部，去掉数据之后的内容，所以一个 24 MiB 游戏的 64 MiB 转储在烧录卡的存储卡上只占 24 MiB。

---

```console
$ kirisute --backup *.nds

Files:  4 ROMs, 112.1 MiB
Plan:   cut each ROM to the size its header declares
        keep each original as <rom>.bak

Trimmed download-play.nds from 32.0 MiB to 8.0 MiB, keeping its download-play
certificate.
Trimmed dsi-enhanced.nds from 64.0 MiB to 24.0 MiB, keeping its DSi area.
Trimmed homebrew.nds from 16.0 MiB to 4.0 MiB.
kirisute: warning: notes.nds has a bad logo checksum and is not a DS ROM, so it
stays as it is.
Trimmed 3 of 4 ROMs and saved 76.0 MiB.
```

<a id="quick-start"></a>

## 快速开始

### 前置条件

| 工具 | 用途 | 安装 |
|:-----|:-----|:-----|
| `awk`、`od`、`head`、`tail`、`tr`、`wc` | 读取头部并复制 ROM 的数据 | Linux 和 macOS 已预装 |
| `mktemp`、`mv`、`stat`、`chmod`、`rm` | 在 ROM 旁边写入裁剪后的副本并替换 | Linux 和 macOS 已预装 |

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
```

## 用法

| 命令 | 用途 |
|:-----|:-----|
| `kirisute [options] <rom>...` | 裁剪每个 ROM 文件，以及所给文件夹中的 `.nds` 文件 |
| 不带参数的 `kirisute` | 在终端中运行时询问 ROM 文件或文件夹，默认为当前文件夹 |
| `kirisute doctor` | 列出所需的工具及各自的种类与版本 |
| `kirisute version`、`kirisute help` | 显示版本或完整的用法说明 |

| 选项 | 作用 |
|:-----|:-----|
| `--dry-run` | 列出会裁剪的内容，不做任何改动 |
| `--info` | 显示每个 ROM 的头部：标题、游戏代码、单元代码、证书、裁剪后大小和填充 |
| `--verify`、`--no-verify` | 只裁剪填充全是 `00` 或 `FF` 字节的 ROM |
| `--backup`、`--no-backup` | 把每个原文件保留为 `<rom>.bak` |
| `--recursive` | 也在所有子文件夹中查找 `.nds` 文件 |
| `--json` | 把结果输出为一个 JSON 对象，供脚本使用 |

`KIRISUTE_VERIFY=yes` 和 `KIRISUTE_BACKUP=yes` 会让 `--verify` 和 `--backup` 成为默认；命令行上的选项优先。kirisute 遵循家族共享的命令行约定，内容见 [FAMILY.md](FAMILY.md)。

```bash
kirisute --dry-run *.nds                 # 看看裁剪能省多少
kirisute --backup --verify game.nds      # 保留原文件，填充中有数据时拒绝
kirisute --recursive ~/roms/nds          # 裁剪整个游戏库
```

<a id="what-is-kept"></a>

## 保留什么

| ROM | 裁剪到 |
|:----|:-------|
| DS | 头部偏移 `0x80` 处的 ROM 大小 |
| 带下载游戏的 DS | 该大小加上其后 136 字节的 RSA 证书 |
| DSi 增强或 DSi 专用 | 头部偏移 `0x210` 处的 DSi 区域大小 |

这些就是 GodMode9 裁剪到的大小。

- 标志或头部校验和错误、小到放不下头部、或头部声明的大小超过文件本身的文件会保持原样并给出警告，运行以状态 1 结束。
- 不加 `--verify` 时，真实大小之后的字节不论内容都会被去掉。加上后，那里只要有 `00` 和 `FF` 以外的字节，该 ROM 就保持原样，警告会指出第一个这样的字节。
- 每个裁剪后的 ROM 先写入旁边的临时文件，赋予原文件的权限，再重命名覆盖原文件，所以中断的运行不会留下写了一半的文件。
- 文件夹只提供其中直接包含的 `.nds` 文件，不分大小写；`--recursive` 最多深入 32 层文件夹。符号链接、`._game.nds` 这样的隐藏文件和隐藏文件夹都不会被处理。

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

测试裁剪的是真实文件：[`test/rom.bash`](test/rom.bash) 会生成校验和正确的 DS、下载游戏和 DSi ROM，标志图像用替代数据，所以仓库中没有任天堂的数据。只有失败是注入的，通过 `PATH` 上的小包装脚本实现。推送到 `main` 且 CI 通过后，semantic-release 会运行：`feat` 或 `fix` 提交会发布新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `KIRISUTE_VERSION` 和 CHANGELOG，并更新 Homebrew formula。

## 许可证

[MIT](LICENSE)
