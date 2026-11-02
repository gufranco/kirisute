<div align="center">

<h1>kirisute</h1>

<strong>ニンテンドー DS と DSi の ROM ファイルを、ヘッダーが宣言する内容を残したまま本来のサイズに切り詰めます。</strong>

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>クイックスタート</strong></a> |
  <a href="#what-is-kept">残すもの</a> |
  <a href="#development">開発</a>
</p>

</div>

DS カートリッジのダンプは元のチップと同じ大きさで、ファイルの末尾は詰め物です。`kirisute` は日本語の「切り捨て」です。各 ROM のヘッダーを読み、データの後ろにあるものを落とすので、24 MiB のゲームの 64 MiB のダンプはフラッシュカートのカード上で 24 MiB になります。

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

## クイックスタート

### 前提条件

| ツール | 用途 | インストール |
|:-------|:-----|:-------------|
| `awk`、`od`、`head`、`tail`、`tr`、`wc` | ヘッダーを読み、ROM のデータを写します | Linux と macOS に標準で入っています |
| `mktemp`、`mv`、`stat`、`chmod`、`rm` | 切り詰めたコピーを ROM の隣に書き、差し替えます | Linux と macOS に標準で入っています |

### インストール

```bash
brew install gufranco/tap/kirisute
```

ソースからもインストールできます。

```bash
git clone https://github.com/gufranco/kirisute.git
cd kirisute
make install
```

`make install` はツール、man ページ、bash・zsh・fish の補完を `~/.local` にコピーし、`kirisute` を `~/.local/bin` に置きます。場所を変えるには `PREFIX` を指定します。Homebrew の formula も同じファイルをインストールします。

### 確認

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

## 使い方

| コマンド | 目的 |
|:---------|:-----|
| `kirisute [options] <rom>...` | 各 ROM ファイルと、指定したフォルダの `.nds` ファイルを切り詰めます |
| 引数なしの `kirisute` | ターミナルでは ROM ファイルかフォルダを尋ねます。既定は現在のフォルダです |
| `kirisute doctor` | 必要なツールを、それぞれの種類とバージョン付きで一覧にします |
| `kirisute version`、`kirisute help` | バージョンか使い方のページを表示します |

| オプション | 効果 |
|:-----------|:-----|
| `--dry-run` | 切り詰める内容を一覧にし、何も変えません |
| `--info` | 各 ROM のヘッダーを表示します。タイトル、ゲームコード、ユニットコード、証明書、切り詰め後のサイズ、詰め物 |
| `--verify`、`--no-verify` | 詰め物が `00` か `FF` だけの ROM だけを切り詰めます |
| `--backup`、`--no-backup` | 元のファイルを `<rom>.bak` として残します |
| `--recursive` | すべてのサブフォルダからも `.nds` ファイルを探します |
| `--json` | 結果を 1 つの JSON オブジェクトで出力します。スクリプト向けです |

`KIRISUTE_VERIFY=yes` と `KIRISUTE_BACKUP=yes` で `--verify` と `--backup` が既定になり、コマンドラインのオプションが優先されます。kirisute はファミリー共通のコマンドライン規約に従います。内容は [FAMILY.md](FAMILY.md) にあります。

```bash
kirisute --dry-run *.nds                 # 切り詰めで減る量を確かめる
kirisute --backup --verify game.nds      # 元を残し、詰め物にデータがあれば断る
kirisute --recursive ~/roms/nds          # ライブラリ全体を切り詰める
```

<a id="what-is-kept"></a>

## 残すもの

| ROM | 切り詰め後 |
|:----|:-----------|
| DS | ヘッダーのオフセット `0x80` にある ROM サイズ |
| ダウンロードプレイ付きの DS | そのサイズに、後ろに続く 136 バイトの RSA 証明書を加えたもの |
| DSi 拡張または DSi 専用 | ヘッダーのオフセット `0x210` にある DSi 領域のサイズ |

これは GodMode9 が切り詰めるサイズと同じです。

- ロゴかヘッダーのチェックサムが違うファイル、ヘッダーより小さいファイル、ファイルより大きいサイズを宣言するファイルは警告付きでそのまま残り、終了ステータスは 1 になります。
- `--verify` がなければ、本来のサイズより後ろのバイトは中身にかかわらず落とします。あれば、そこに `00` と `FF` 以外があればその ROM は残り、警告は最初のそのバイトを示します。
- 切り詰めた ROM は隣の一時ファイルに書き、元の権限を付けてから上書きの名前変更をするので、中断しても半端なファイルは残りません。
- フォルダは直下の `.nds` ファイルだけを、大文字小文字を問わず対象にします。`--recursive` は 32 階層まで降ります。シンボリックリンク、`._game.nds` のような隠しファイル、隠しフォルダには触れません。

## 移植性

すべて POSIX `sh` で書かれ、ShellCheck `-o all` の指摘はゼロです。テストは macOS では `/bin/sh`、`dash`、システムの bash 3.2 と zsh、Homebrew の最新の bash と zsh で、Ubuntu では `dash`、`bash`、`bash --posix`、`zsh` で実行します。CI はファミリーの 6 つのツールセットで繰り返します。Linux の uutils、GNU、BusyBox、macOS 標準のツール、その Homebrew の新しいビルド、Homebrew の uutils です。`kirisute doctor` は各ツールの種類とバージョンを示すので、バグ報告からどのツールが動いたかがわかります。

<a id="development"></a>

## 開発

| コマンド | 説明 |
|:---------|:-----|
| `make fmt` | すべてのスクリプトを shfmt で整形します |
| `make lint` | shfmt、すべてのスクリプト・テスト・補完への ShellCheck、名前の検査、man ページへの mandoc |
| `make test` | システムの `sh` で `bats` テストを実行します |
| `make test-all` | すべてのシェルで同じテストを実行します。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu コンテナで同じテストを実行します |
| `make coverage` | この Mac と Ubuntu コンテナでの bashcov 行カバレッジを統合し、CI と同じ 100% のゲートをかけます |

テストは本物のファイルを切り詰めます。[`test/rom.bash`](test/rom.bash) がチェックサムの正しい DS、ダウンロードプレイ、DSi の ROM を作り、ロゴの画像には代わりのデータを使うので、リポジトリに任天堂のデータはありません。注入するのは失敗だけで、`PATH` 上の小さなラッパーを通します。`main` への push で CI が通ると semantic-release が動き、`feat` か `fix` のコミットがリリースを公開して、[`lib/core.sh`](lib/core.sh) の `KIRISUTE_VERSION` と CHANGELOG を更新し、Homebrew の formula を上げます。

## ライセンス

[MIT](LICENSE)
