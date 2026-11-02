<div align="center">

<h1>kirisute</h1>

<strong>把任天堂 DS 和 DSi 的 ROM 檔案剪裁至真正的大小，保留標頭所聲明的一切內容。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文 (香港)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速開始</strong></a> |
  <a href="#what-is-kept">保留甚麼</a> |
  <a href="#development">開發</a>
</p>

</div>

DS 卡帶的轉儲與原來的晶片一樣大，檔案末端是填充資料。`kirisute` 是日語的「切り捨て」，意思是捨去餘下的部分：它讀取每個 ROM 的標頭，刪去資料之後的內容，所以一個 24 MiB 遊戲的 64 MiB 轉儲在燒錄卡的記憶卡上只佔 24 MiB。

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

## 快速開始

### 先決條件

| 工具 | 用途 | 安裝 |
|:-----|:-----|:-----|
| `awk`、`od`、`head`、`tail`、`tr`、`wc` | 讀取標頭並複製 ROM 的資料 | Linux 和 macOS 已預載 |
| `mktemp`、`mv`、`stat`、`chmod`、`rm` | 在 ROM 旁寫入剪裁後的副本並替換 | Linux 和 macOS 已預載 |

### 安裝

```bash
brew install gufranco/tap/kirisute
```

亦可從原始碼安裝：

```bash
git clone https://github.com/gufranco/kirisute.git
cd kirisute
make install
```

`make install` 會把工具、man 說明頁，以及 bash、zsh 和 fish 的自動完成複製到 `~/.local`，並把 `kirisute` 放進 `~/.local/bin`；設定 `PREFIX` 可更改位置。Homebrew formula 會安裝同樣的檔案。

### 驗證

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

| 指令 | 用途 |
|:-----|:-----|
| `kirisute [options] <rom>...` | 剪裁每個 ROM 檔案，以及所給資料夾內的 `.nds` 檔案 |
| 不帶參數的 `kirisute` | 在終端機中執行時詢問 ROM 檔案或資料夾，預設為目前的資料夾 |
| `kirisute doctor` | 列出所需的工具及各自的種類與版本 |
| `kirisute version`、`kirisute help` | 顯示版本或完整的用法說明 |

| 選項 | 作用 |
|:-----|:-----|
| `--dry-run` | 列出會剪裁的內容，不作任何改動 |
| `--info` | 顯示每個 ROM 的標頭：標題、遊戲代碼、單元代碼、證書、剪裁後大小和填充資料 |
| `--verify`、`--no-verify` | 只剪裁填充資料全是 `00` 或 `FF` 位元組的 ROM |
| `--backup`、`--no-backup` | 把每個原檔保留為 `<rom>.bak` |
| `--recursive` | 亦在所有子資料夾中尋找 `.nds` 檔案 |
| `--json` | 把結果輸出為一個 JSON 物件，供腳本使用 |

`KIRISUTE_VERIFY=yes` 和 `KIRISUTE_BACKUP=yes` 會令 `--verify` 和 `--backup` 成為預設；指令行上的選項優先。kirisute 遵從家族共用的指令行約定，內容見 [FAMILY.md](FAMILY.md)。

```bash
kirisute --dry-run *.nds                 # 看看剪裁能節省多少
kirisute --backup --verify game.nds      # 保留原檔，填充資料中有內容便拒絕
kirisute --recursive ~/roms/nds          # 剪裁整個遊戲庫
```

<a id="what-is-kept"></a>

## 保留甚麼

| ROM | 剪裁至 |
|:----|:-------|
| DS | 標頭偏移 `0x80` 處的 ROM 大小 |
| 附下載遊玩的 DS | 該大小加上其後 136 位元組的 RSA 證書 |
| DSi 增強或 DSi 專用 | 標頭偏移 `0x210` 處的 DSi 區域大小 |

這些就是 GodMode9 剪裁至的大小。

- 標誌或標頭校驗和錯誤、小得容不下標頭、或標頭聲明的大小超過檔案本身的檔案，會保持原狀並發出警告，執行以狀態 1 結束。
- 沒有 `--verify` 時，真正大小之後的位元組不論內容都會被刪去。加上之後，那裏只要有 `00` 和 `FF` 以外的位元組，該 ROM 便保持原狀，警告會指出第一個這樣的位元組。
- 每個剪裁後的 ROM 先寫入旁邊的暫存檔，賦予原檔的權限，再改名覆蓋原檔，所以中斷的執行不會留下寫了一半的檔案。
- 資料夾只提供直接放在其中的 `.nds` 檔案，不分大小寫；`--recursive` 最多深入 32 層資料夾。符號連結、`._game.nds` 這類隱藏檔案和隱藏資料夾都不會處理。

## 可攜性

全部以 POSIX `sh` 編寫，ShellCheck `-o all` 零警告。測試在 macOS 上於 `/bin/sh`、`dash`、系統內置的 bash 3.2 和 zsh、Homebrew 最新的 bash 和 zsh 下執行，在 Ubuntu 上於 `dash`、`bash`、`bash --posix` 和 `zsh` 下執行。CI 會在家族的六種工具組合上重複這些測試：Linux 的 uutils、GNU 或 BusyBox 工具，以及 macOS 內置的工具、Homebrew 的較新版本或 Homebrew 的 uutils 工具。`kirisute doctor` 會列出每個工具的種類與版本，讓錯誤報告說明執行的是哪些工具。

<a id="development"></a>

## 開發

| 指令 | 說明 |
|:-----|:-----|
| `make fmt` | 以 shfmt 格式化所有腳本 |
| `make lint` | shfmt、對所有腳本、測試和自動完成執行 ShellCheck、名稱檢查，以及對 man 說明頁執行 mandoc |
| `make test` | 在系統 `sh` 下執行 `bats` 測試 |
| `make test-all` | 在每種 shell 下執行同樣的測試，macOS 上包括 bash 和 zsh 的兩個版本 |
| `make test-linux` | 在 Ubuntu 容器內執行同樣的測試 |
| `make coverage` | 合併本機與 Ubuntu 容器內的 bashcov 行覆蓋率，並執行與 CI 相同的 100% 門檻 |

測試剪裁的是真實檔案：[`test/rom.bash`](test/rom.bash) 會製作校驗和正確的 DS、下載遊玩和 DSi ROM，標誌圖像以替代資料代替，所以儲存庫中沒有任天堂的資料。只有失敗是注入的，經 `PATH` 上的小型包裝腳本進行。推送到 `main` 而 CI 通過後，semantic-release 便會執行：`feat` 或 `fix` 提交會發佈新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `KIRISUTE_VERSION` 和 CHANGELOG，並更新 Homebrew formula。

## 授權

[MIT](LICENSE)
