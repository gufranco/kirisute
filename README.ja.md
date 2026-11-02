<div align="center">

<h1>kirisute</h1>

<strong>ゲームボーイアドバンス、DS、DSi、3DS の ROM と PSP の ISO を本来のサイズに切り詰め、ヘッダーに従って名前を付けます。</strong>

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [繁體中文 (香港)](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/gufranco/kirisute/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/gufranco/kirisute/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/gufranco/kirisute?style=flat-square&label=release)](https://github.com/gufranco/kirisute/releases/latest)
[![license](https://img.shields.io/github/license/gufranco/kirisute?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>クイックスタート</strong></a> |
  <a href="#what-is-kept">残すもの</a> |
  <a href="#rename">名前の変更</a> |
  <a href="#compress">圧縮</a> |
  <a href="#development">開発</a>
</p>

</div>

カートリッジのダンプは元のチップと同じ大きさで、ディスクイメージも最後のセクターの後ろに詰め物を持つことがあります。`kirisute` は日本語の「切り捨て」です。各ファイルのヘッダーを読み、データの後ろにあるものを落とすので、24 MiB のゲームの 64 MiB のダンプはフラッシュカートのカード上で 24 MiB になります。

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

## クイックスタート

### 前提条件

| ツール | 用途 | インストール |
|:-------|:-----|:-------------|
| `awk`、`od`、`head`、`tail`、`tr`、`wc` | ヘッダーを読み、ROM のデータを写します | Linux と macOS に標準で入っています |
| `mktemp`、`mv`、`stat`、`chmod`、`rm` | 切り詰めたコピーを ROM の隣に書き、差し替えます | Linux と macOS に標準で入っています |
| `cmp` | 圧縮したコピーが元に戻ることを確かめます | Linux と macOS に標準で入っています |
| [maxcso](https://github.com/unknownbrackets/maxcso) | `compress` の CSO と ZSO のコピーを書きます | `brew install gufranco/tap/maxcso`。Homebrew の formula が一緒に入れます |

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
cmp                ok       /opt/homebrew/bin/cmp, gnu 3.12
maxcso             ok       /opt/homebrew/bin/maxcso, 1.13.0
```

## 使い方

| コマンド | 目的 |
|:---------|:-----|
| `kirisute [options] <rom>...` | 各 ROM ファイルと、指定したフォルダの ROM ファイルを切り詰めます |
| `kirisute rename [options] <rom>...` | 各 ROM の名前を、ヘッダーのタイトルとコードに変えます |
| `kirisute compress [options] <iso>...` | 各 PSP ディスクイメージの CSO または ZSO のコピーを ARK-4 と ARK-5 向けに書きます |
| 引数なしの `kirisute` | ターミナルでは ROM ファイルかフォルダを尋ねます。既定は現在のフォルダです |
| `kirisute doctor` | 必要なツールを、それぞれの種類とバージョン付きで一覧にします |
| `kirisute version`、`kirisute help` | バージョンか使い方のページを表示します |

| オプション | 効果 |
|:-----------|:-----|
| `--dry-run` | 切り詰めや名前の変更の内容を一覧にし、何も変えません |
| `--info` | 各 ROM のヘッダーを表示します。タイトル、コード、システムごとの項目、切り詰め後のサイズ、詰め物 |
| `--verify`、`--no-verify` | 詰め物が `00` か `FF` だけの ROM だけを切り詰めます |
| `--backup`、`--no-backup` | 元のファイルを `<rom>.bak` として残します |
| `--recursive` | すべてのサブフォルダからも ROM ファイルを探します |
| `--json` | 結果を 1 つの JSON オブジェクトで出力します。スクリプト向けです |

`KIRISUTE_VERIFY=yes` と `KIRISUTE_BACKUP=yes` で `--verify` と `--backup` が既定になり、コマンドラインのオプションが優先されます。kirisute はファミリー共通のコマンドライン規約に従います。内容は [FAMILY.md](FAMILY.md) にあります。

```bash
kirisute --dry-run *.nds *.3ds           # 切り詰めで減る量を確かめる
kirisute --backup --verify game.nds      # 元を残し、詰め物にデータがあれば断る
kirisute --recursive ~/roms              # ライブラリ全体を切り詰める
kirisute rename --dry-run *.gba          # 各 ROM が付ける名前を確かめる
kirisute compress game.iso               # ARK-4 と ARK-5 向けに game.cso を書く
```

<a id="what-is-kept"></a>

## 残すもの

| ファイル | 拡張子 | 切り詰め後 |
|:---------|:-------|:-----------|
| DS | `.nds` | ヘッダーのオフセット `0x80` にある ROM サイズ |
| ダウンロードプレイ付きの DS | `.nds` | そのサイズに、後ろに続く 136 バイトの RSA 証明書を加えたもの |
| DSi 拡張または DSi 専用 | `.nds` | ヘッダーのオフセット `0x210` にある DSi 領域のサイズ |
| ゲームボーイアドバンス | `.gba` | 詰め物でない最後のバイトまで。4 バイト単位に切り上げ、512 バイト以上減るときだけ |
| 3DS カートリッジイメージ | `.3ds`、`.cci` | 最後のパーティションの終わり。ヘッダーが定めるメディア単位で数えます |
| 3DS 実行ファイル | `.cxi` | NCCH ヘッダーが宣言するサイズ |
| PSP ディスクイメージ | `.iso` | ISO 9660 のボリューム記述子が宣言するボリューム。その後ろがすべて `00` か `FF` のときだけ |

- 各ファイルは触る前に検査します。DS とゲームボーイアドバンスの ROM は正しいロゴとヘッダーのチェックサムが必要です。3DS イメージは NCSD のマジック、メディア ID、順番どおりのパーティションが必要で、本体 NAND のイメージは断ります。PSP イメージはシステム名 `PSP GAME`、`UMD VIDEO`、`UMD AUDIO` のどれか、または `PSP_GAME` フォルダが必要です。検査に通らないファイル、ヘッダーより小さいファイル、ファイルより大きいサイズを宣言するファイルは警告付きでそのまま残り、終了ステータスは 1 になります。
- `--verify` がなければ、本来のサイズより後ろのバイトは中身にかかわらず落とします。あれば、そこに `00` と `FF` 以外があればその ROM は残り、警告は最初のそのバイトを示します。
- PSP イメージには常にこの検査をかけます。ダンプツールはファイルシステムではなくディスクの最後のセクターでイメージの大きさを決め、ゲームはファイルの外のセクターも読めるので、kirisute は詰め物だと確かめられないデータを決して切りません。ボリュームの中のものも決して消しません。アップデートデータ、詰め物ファイル、動画はすべて残ります。`USER_L0.IMG` と `USER_L1.IMG` を持つ開発用 DVD-R イメージは、2 つのレイヤーをつなぐまで断ります。
- 切り詰めたファイルは、Redump や No-Intro のようなデータベースにある切り詰める前のダンプのチェックサムとは一致しなくなります。`--backup` で元のファイルを残せます。
- 切り詰めた ROM は隣の一時ファイルに書き、元の権限を付けてから上書きの名前変更をするので、中断しても半端なファイルは残りません。
- フォルダは直下にある上の拡張子のファイルだけを、大文字小文字を問わず対象にします。`--recursive` は 32 階層まで降ります。名前で指定したほかの拡張子のファイルは DS の ROM として読みます。シンボリックリンク、`._game.nds` のような隠しファイル、隠しフォルダには触れません。

<a id="rename"></a>

## 名前の変更

`kirisute rename` は各 ROM にヘッダーに従った名前を付けるので、ダンプのフォルダが目録のように読めます。

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

- 名前は `<タイトル> (<コード>)` です。3DS イメージのようにヘッダーにタイトルがなければコードだけになります。PSP イメージはタイトルとディスク ID を `PSP_GAME/PARAM.SFO` から取ります。
- 拡張子は小文字にします。タイトルのスラッシュとコロンはハイフンになり、制御文字は落とします。
- ほかのファイルがすでに持つ名前は決して取りません。その ROM は警告付きでそのまま残ります。大文字小文字だけの変更も Mac のディスクで動きます。
- `rename` は `--dry-run`、`--recursive`、`--json` を受け付けます。

<a id="compress"></a>

## 圧縮

`kirisute compress` は [maxcso](https://github.com/unknownbrackets/maxcso) で各 PSP ディスクイメージの圧縮コピーを、カスタムファームウェア ARK-4 と ARK-5 が読める形式で書き、元のファイルは残します。

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

| オプション | 効果 | 既定 |
|:-----------|:-----|:-----|
| `--format cso` | CSO v1。deflate のみで、古いファームウェアも読める形式。3 つの中で読み込みが最も遅い | |
| `--format cso2` | CSO v2。ブロックごとに deflate か LZ4 を選び、小さく読み込みも速い | 既定 |
| `--format zso` | ZSO。LZ4 のみで読み込みが最も速く、ファイルは大きめ | |
| `--block N` | ブロックサイズ。2048、4096、8192、16384 バイト。大きいほどわずかによく縮みます | 8192 |
| `--lz4-cost N` | CSO v2 で、LZ4 の増分が N% 以内のブロックに LZ4 を使い、容量と読み込み速度を引き換えます。0 なら LZ4 が小さいブロックだけです | 0 |
| `--best` | 遅い試行を 1 つ加えます。CSO v1 と v2 には Zopfli、ZSO には総当たりの LZ4。わずかに小さく、作るのはずっと遅くなります | オフ |

`KIRISUTE_FORMAT`、`KIRISUTE_BLOCK`、`KIRISUTE_LZ4_COST`、`KIRISUTE_BEST` で同じ既定を設定できます。

- コピーの名前は `game.cso` か `game.zso` で、ARK が一覧に出す拡張子です。CSO v2 も `.cso` です。`.cso2` という名前は本体に表示されません。
- コピーは元のファイルにバイト単位で戻ると確かめてから残します。確認の間はイメージと同じ大きさの空き容量が要ります。既存のコピーは上書きしません。
- DAX と JSO は書きません。maxcso の DAX のブロックには ARK が想定する zlib ヘッダーがなく、オープンソースの JSO ライターは存在しません。JSO の速い読み込みは ZSO で得られます。
- 既定の設定は `maxcso --format=cso2 --block=8192 --use-zlib --use-7zdeflate --use-lz4 --use-lz4brute` と同じバイト列を書き、そのコピーは ARK-4 と ARK-5 で起動します。大きい `--lz4-cost`、`--best`、CSO v1、ZSO は ARK のリーダーが読める形式ですが、まだ本体では試していません。
- 詰め物を消したいときは先に切り詰めてください。圧縮でもゼロの並びはほとんど場所を取りません。

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

テストは本物のファイルを切り詰めます。システムごとのビルダーが、ヘッダーとチェックサムの正しいファイルを作ります。DS は [`test/rom.bash`](test/rom.bash)、ほかに [`test/gba.bash`](test/gba.bash)、3DS は [`test/ctr.bash`](test/ctr.bash)、[`test/psp.bash`](test/psp.bash) です。ロゴの画像には代わりのデータを使うので、リポジトリに任天堂やソニーのデータはありません。注入するのは失敗だけで、`PATH` 上の小さなラッパーを通します。`main` への push で CI が通ると semantic-release が動き、`feat` か `fix` のコミットがリリースを公開して、[`lib/core.sh`](lib/core.sh) の `KIRISUTE_VERSION` と CHANGELOG を更新し、Homebrew の formula を上げます。

## ライセンス

[MIT](LICENSE)
