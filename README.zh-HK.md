<div align="center">

<h1>kirisute</h1>

<strong>把 Game Boy Advance、DS、DSi 和 3DS 的 ROM 以及 PSP 的 ISO 剪裁至真正的大小，並按標頭資料命名。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文 (香港)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速開始</strong></a> |
  <a href="#what-is-kept">保留甚麼</a> |
  <a href="#rename">重新命名</a> |
  <a href="#development">開發</a>
</p>

</div>

卡帶的轉儲與原來的晶片一樣大，光碟映像亦可能在最後一個磁區之後帶有填充資料。`kirisute` 是日語的「切り捨て」，意思是捨去餘下的部分：它讀取每個檔案的標頭，刪去資料之後的內容，所以一個 24 MiB 遊戲的 64 MiB 轉儲在燒錄卡的記憶卡上只佔 24 MiB。

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
| `kirisute [options] <rom>...` | 剪裁每個 ROM 檔案，以及所給資料夾內的 ROM 檔案 |
| `kirisute rename [options] <rom>...` | 按標頭中的標題和代碼重新命名每個 ROM |
| 不帶參數的 `kirisute` | 在終端機中執行時詢問 ROM 檔案或資料夾，預設為目前的資料夾 |
| `kirisute doctor` | 列出所需的工具及各自的種類與版本 |
| `kirisute version`、`kirisute help` | 顯示版本或完整的用法說明 |

| 選項 | 作用 |
|:-----|:-----|
| `--dry-run` | 列出會剪裁或重新命名的內容，不作任何改動 |
| `--info` | 顯示每個 ROM 的標頭：標題、代碼、各系統獨有的欄位、剪裁後大小和填充資料 |
| `--verify`、`--no-verify` | 只剪裁填充資料全是 `00` 或 `FF` 位元組的 ROM |
| `--backup`、`--no-backup` | 把每個原檔保留為 `<rom>.bak` |
| `--recursive` | 亦在所有子資料夾中尋找 ROM 檔案 |
| `--json` | 把結果輸出為一個 JSON 物件，供腳本使用 |

`KIRISUTE_VERIFY=yes` 和 `KIRISUTE_BACKUP=yes` 會令 `--verify` 和 `--backup` 成為預設；指令行上的選項優先。kirisute 遵從家族共用的指令行約定，內容見 [FAMILY.md](FAMILY.md)。

```bash
kirisute --dry-run *.nds *.3ds           # 看看剪裁能節省多少
kirisute --backup --verify game.nds      # 保留原檔，填充資料中有內容便拒絕
kirisute --recursive ~/roms              # 剪裁整個遊戲庫
kirisute rename --dry-run *.gba          # 看看每個 ROM 會取甚麼名稱
```

<a id="what-is-kept"></a>

## 保留甚麼

| 檔案 | 副檔名 | 剪裁至 |
|:-----|:-------|:-------|
| DS | `.nds` | 標頭偏移 `0x80` 處的 ROM 大小 |
| 附下載遊玩的 DS | `.nds` | 該大小加上其後 136 位元組的 RSA 證書 |
| DSi 增強或 DSi 專用 | `.nds` | 標頭偏移 `0x210` 處的 DSi 區域大小 |
| Game Boy Advance | `.gba` | 最後一個非填充位元組，向上取整至 4 位元組，且只在能節省至少 512 位元組時剪裁 |
| 3DS 卡帶映像 | `.3ds`、`.cci` | 最後一個分區的結尾，按標頭設定的媒體單位計算 |
| 3DS 執行檔 | `.cxi` | NCCH 標頭聲明的大小 |
| PSP 光碟映像 | `.iso` | ISO 9660 卷描述符聲明的卷，且只在其後全是 `00` 或 `FF` 時剪裁 |

- 每個檔案在處理前都會檢查。DS 和 Game Boy Advance 的 ROM 需要正確的標誌和標頭校驗和；3DS 映像需要 NCSD 魔數、媒體 ID 和次序正確的分區，主機 NAND 映像會被拒絕；PSP 映像需要系統名稱 `PSP GAME`、`UMD VIDEO` 或 `UMD AUDIO`，或者 `PSP_GAME` 資料夾。檢查不通過、小得容不下標頭、或標頭聲明的大小超過檔案本身的檔案，會保持原狀並發出警告，執行以狀態 1 結束。
- 沒有 `--verify` 時，真正大小之後的位元組不論內容都會被刪去。加上之後，那裏只要有 `00` 和 `FF` 以外的位元組，該 ROM 便保持原狀，警告會指出第一個這樣的位元組。
- PSP 映像一定會做這項檢查。轉儲工具按光碟的最後一個磁區而非檔案系統決定映像大小，遊戲亦能讀取檔案以外的磁區，所以 kirisute 絕不剪去無法證明是填充資料的內容。卷內的內容亦絕不刪除：更新資料、填充檔案和影片都會保留。含有 `USER_L0.IMG` 和 `USER_L1.IMG` 的開發用 DVD-R 映像會被拒絕，直至把兩層接合起來。
- 剪裁後的檔案不再與 Redump 或 No-Intro 等資料庫中未剪裁轉儲的校驗和相符。`--backup` 可保留原檔。
- 每個剪裁後的 ROM 先寫入旁邊的暫存檔，賦予原檔的權限，再改名覆蓋原檔，所以中斷的執行不會留下寫了一半的檔案。
- 資料夾只提供直接放在其中、副檔名屬於上表的檔案，不分大小寫；`--recursive` 最多深入 32 層資料夾。按名稱給出的其他副檔名檔案會當作 DS ROM 讀取。符號連結、`._game.nds` 這類隱藏檔案和隱藏資料夾都不會處理。

<a id="rename"></a>

## 重新命名

`kirisute rename` 按標頭資料為每個 ROM 命名，令一整個資料夾的轉儲讀起來像一份目錄：

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

- 名稱是 `<標題> (<代碼>)`；如 3DS 映像般標頭沒有標題時，只用代碼。PSP 映像的標題和光碟 ID 取自 `PSP_GAME/PARAM.SFO`。
- 副檔名保持小寫。標題中的斜線和冒號會變成連字號，控制字元會被刪去。
- 絕不會佔用其他檔案已有的名稱：那個 ROM 會保持原狀並發出警告。只改變大小寫的重新命名在 Mac 的磁碟上亦能完成。
- `rename` 接受 `--dry-run`、`--recursive` 和 `--json`。

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

測試剪裁的是真實檔案。每個系統都有一個產生器，寫出標頭和校驗和都正確的檔案：DS 用 [`test/rom.bash`](test/rom.bash)，另有 [`test/gba.bash`](test/gba.bash)、3DS 用 [`test/ctr.bash`](test/ctr.bash) 和 [`test/psp.bash`](test/psp.bash)。標誌圖像以替代資料代替，所以儲存庫中沒有任天堂或索尼的資料。只有失敗是注入的，經 `PATH` 上的小型包裝腳本進行。推送到 `main` 而 CI 通過後，semantic-release 便會執行：`feat` 或 `fix` 提交會發佈新版本，更新 [`lib/core.sh`](lib/core.sh) 中的 `KIRISUTE_VERSION` 和 CHANGELOG，並更新 Homebrew formula。

## 授權

[MIT](LICENSE)
