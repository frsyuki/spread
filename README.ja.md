SpreadOSD
=========
SpreadOSD - 分散ストレージシステム


## 概要

SpreadOSDは、画像、音声、動画などの大きなデータを保存するのに適した、分散ストレージシステムです。
高い **拡張性**、**可用性**、**保守性** を持ち、優れた性能を発揮します。


## 拡張性

サーバを追加することで、ストレージの容量とI/Oスループットが向上します。
クラスタの構成はアプリケーションから隠蔽されるので、アプリケーションを停止したり設定しなおしたりすることなくサーバを追加することができます。


## 可用性

SpreadOSDはレプリケーションをサポートしています。数台のサーバが故障してもデータが失われることはありません。アプリケーションからのリクエストも通常通り処理されます。

SpreadOSDのレプリケーション戦略は、マルチマスタ･レプリケーションの組み合わせです。マスタサーバが故障した場合は、別のマスタサーバが最小のダウンタイムで即座にフェイルオーバーします。

また、SpreadOSDはデータセンタをまたいだレプリケーション（地理を考慮したレプリケーション）をサポートしています。それぞれのデータは複数のデータセンタに保存されるため、災害に備えることができます。


## 保守性

SpreadOSDは、すべてのデータサーバを一斉に制御するための管理ツールを同梱しています。また監視ツールを使ってサーバの負荷を可視化することもできます。
クラスタの規模が大きくなっても管理コストが増大しにくいと言いえます。


## データモデル

SpreadOSDは、**キー**（文字列）によって識別される*オブジェクト*の集合を保存します。それぞれのオブジェクトは、**データ**（バイト列）と**属性**（連想配列）を持ちます。

        key             data                  attributes
    +----------+-------------------+---------------------------------+
    | "image1" |  "HTJ P N G" ...  |  { type:png, date:2011-07-29 }  |
    +----------+-------------------+---------------------------------+
    |  key     |  bytes .........  |  { key:value, key:value, ... }  |
    +----------+-------------------+---------------------------------+
    |  key     |  bytes .........  |  { key:value, key:value, ... }  |
    +----------+-------------------+---------------------------------+
    ...

また、オブジェクトは複数のバージョンを持つことができます。
明示的に削除しない限りは、古いバージョンのオブジェクトを取り出すことができます。
それぞれのバージョンは、名前か作成時刻（協定世界時のUNIX時刻）で識別されます。

TODO: See APIリファレンス


## もっと知るには

  - TODO: See アーキテクチャ
  - TODO: See インストール
  - TODO: See APIリファレンス


## ライセンス

    Copyright (C) 2010  FURUHASHI Sadayuki
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.
    
    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

See also NOTICE file.



SpreadOSD アーキテクチャ
========================

SpreadOSDは、高い拡張性と可用性を持った分散ストレージシステムです。
ここではそのアーキテクチャについて述べます。

## サーバの種類

SpreadOSDは、次の4種類のサーバから構成されます：

  - **DS (Data Server)** は、コンテンツをディスク上に保存したりレプリケーションしたりします。
  - **MDS (Metadata Server)** は、コンテンツのメタデータを保存します。メタデータにはコンテンツがどのDSに保存されているかを示す情報も含まれています。MDSには[Tokyo Tyrant](http://fallabs.com/tokyotyrant/)を使います。
  - **GW (Gateway)** は、アプリケーションからの要求を受け取り、適切なDSに中継します。DSはGWの機能も併せ持っているため、DSをGWとして使うこともできます。
  - **CS (Configuration Server)** は、クラスタの設定情報を管理します。また、DSの状態を監視し、故障したDSを自動的に切り離します。

**レプリケーション･セット**は、複数のDSで構成されるグループです。同じレプリケーション･セットに属するDSは、同じデータをレプリケーションして保存しています。


                        App     App     App
                         |       |       |  HTTP or MessagePack-RPC
            ----------- GW      GW      GW or DS
           /            /
    +-------------+    |  GWはアプリケーションからDSにリクエストを中継
    | TokyoTyrant |    |
    |      |      |  +----+   +----+   +----+
    | TokyoTyrant |  | DS |   | DS |   | DS |
    |      |      |  |    |   |    |   |    | レプリケーション･セット
    | TokyoTyrant |  | DS |   | DS |   | DS | 同じレプリケーション･セット内のDSは同じデータを保存
    +-------------+  |    |   |    |   |    |
    MDS              | DS |   | DS |   | DS | ... レプリケーションセットはいつでも追加可能
    メタデータを保存 +----+   +----+   +----+
                         \       |       /
                          -----  |  ----- CSはクラスタの設定情報を管理
                               \ | /
                                CS


## 操作

### データの保存

GW (Gateway) （または DS (Data Server)）は、アプリケーションからの要求をMDSとDSに中継します。

MDS (Metadata Server) は「実際のデータがどこに保存されているか」を保存しており、DSは実際にデータを保存しています。

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /            /
    +-------------+    |
    |             |    | (3)
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | | (4)  |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | | (4)  |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. アプリケーションはGWかDSに要求を送信します。どのGWやDSを選んでも構いません。
  2. GW（やDS）は、実際にデータを保存するレプリケーション･セットを選択し、そのIDをMDSに書き込みます。レプリケーション･セットの選択には、重み付きのround-robinアルゴリズムを使います。
  3. GW（やDS）は、レプリケーション･セット内のDSに追加要求を送信します。
  4. レプリケーション･セット内の他のDSは、保存されたデータをレプリケーションします。


### データの取得

MDS (Metadata Server) は、どのレプリケーション･セットに実際のデータが保存されているかを知っています。このためGW (Gatway) （やDS (Data Server) ）は、まずMDSに問い合わせ、その後データをDSから取得します。

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /            /
    +-------------+    |
    |             |    | (3)
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. アプリケーションはGWかDSに要求を送信します。どのGWやDSを選んでも構いません。
  2. GW（またはDS）は、検索クエリをMDSに送信します。MDSは実際にデータを保存しているレプリケーション･セットのIDを返します。
  3. GW（またはDS）は、そのレプリケーション･セット内のDSに対して取得要求を送信します。DSは位置を考慮したアルゴリズムによって選択されます。（TODO: See HowTo Geo-redundancy）


### 属性の保存と取得

属性は MDS (Metadata Server) に保存されています。

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /
    +-------------+
    |             |
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | |  |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | |  |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. アプリケーションはGWかDSに要求を送信します。どのGWやDSを選んでも構いません。
  2. GW（DS）は、クエリをMDSに送信します。


## 管理と監視

すべてのデータサーバ CS (Configuration Server) に登録されています。管理ツールや監視ツールは、CSの設定を書き換えたり、CSからサーバの一覧表を取得することで、すべてのDSを一斉に制御したり情報を収集したりします。

                     (1)      (2)
       Administrator --> Tool --> CS
                         / \
    +-------------+     |   -------------  (3)
    |             |     |       |        \
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | |  |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | |  |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. 管理者（あなた）が管理ツールを実行します。
  2. 管理ツールは、CSからクラスタの情報を取得します。
  3. 管理ツールは、状態や統計情報をDSから取得して表示します。

TODO: See 運用


SpreadOSD インストール
======================

SpreadOSDは Ruby で実装された分散ストレージシステムです。
make installでインストールするか、RubyGemsを使ってインストールすることができます。


## 依存ライブラリ

SpreadOSDを実行するには次のソフトウェアが必要です：

  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) &gt;= 1.1.40
  - [ruby](http://www.ruby-lang.org/) &gt;= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) &gt;= 0.4.3
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) &gt;= 1.13
  - [rack gem](http://rubygems.org/gems/rack) &gt;= 1.2.1


## 方法1：RubyGemsを使ったインストール

1つ目のインストール方法は、rake と gem を使う方法です：

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

もしRubyを広く使っているのであれば、RubyGemsを使ってバージョンを管理するのが良い方法でしょう。

## 方法2：make installを使ったインストール

もう1つの方法は、./configure && make install を使う方法です：

    $ ./bootstrap  # 必要な場合
    $ ./configure RUBY=/usr/local/bin/ruby
    $ make
    $ sudo make install

以下のコマンドがインストールされます：

  - spreadctl: 管理ツール
  - spreadcli: コマンドラインクライアント
  - spread-cs: CSサーバプログラム
  - spread-ds: DSサーバプログラム
  - spread-gw: GWサーバプログラム


## 専用のRuby 1.9をインストールする

ここでは /opt/local/spread ディレクトリに全システムをコンパイルしてインストールします。

まず、以下のパッケージをパッケージ管理ツールを使ってインストールしてください：

  - gcc-g++ &gt;= 4.1
  - openssl-devel (or libssl-dev) to build ruby
  - zlib-devel (or zlib1g-dev) to build ruby
  - readline-devel (or libreadline6-dev) to build ruby
  - tokyocabinet (or libtokyocabinet-dev) to build Tokyo Tyrant

以下の手順でRubyとSpreadOSDをインストールします：

    # Installs ruby-1.9 into /opt/local/spread
    $ wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p0.tar.bz2
    $ tar jxvf ruby-1.9.2-p0.tar.bz2
    $ cd ruby-1.9.2
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # Installs required gems
    $ sudo /opt/local/spread/bin/gem install msgpack-rpc
    $ sudo /opt/local/spread/bin/gem install tokyotyrant
    $ sudo /opt/local/spread/bin/gem install rack
    
    # Installs SpreadOSD
    $ git clone http://github.com/frsyuki/spread.git
    $ cd spread
    $ ./configure RUBY=/opt/local/spread/bin/ruby --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # Installs Tokyo Tyrant into /opt/local/spread
    $ wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz
    $ tar zxvf tokyotyrant-1.1.41.tar.gz
    $ cd tokyotyrant-1.1.41
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install


SpreadOSD システムの構築
========================

ここではSpreadOSDクラスタを構築する方法について述べます。

## 1台のホスト上で動かす

SpreadOSDを1台のホスト上で動かしてテストすることができます：

    # 1. MDS（Tokyo Tyrant）を起動する
    #    ここでは単一ノード構成で起動します
    [localhost]$ ttserver mds.tct &
    
    # 2. CSを起動する
    #    --mds (MDSのアドレス) と -s (設定ディレクトリ) 引数が必要です
    [localhost]$ mkdir data-cs
    [localhost]$ spread-cs --mds 127.0.0.1 -s ./data-cs &
    
    # 3. DSを起動する
    #    次の引数が必要です：
    #      --cs (CSのアドレス)
    #      --address (このノードのアドレス)
    #      --nid (一意なノードID)
    #      --rsid (参加するレプリケーション･セットのID)
    #      --name (分かりやすいノード名)
    #      --store (ストレージへのパス)
    [localhost]$ mkdir data-ds0
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18900 --nid 0 --rsid 0 \
                           --name ds0 --store ./data-ds0 &
    
    # 4. さらにDSを起動していく...
    [localhost]$ mkdir data-ds1
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18901 --nid 1 --rsid 0 \
                           --name ds1 --store ./data-ds1 &
    
    [localhost]$ mkdir data-ds2
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18902 --nid 2 --rsid 1 \
                           --name ds2 --store ./data-ds2 &
    
    [localhost]$ mkdir data-ds3
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18903 --nid 3 --rsid 1 \
                           --name ds3 --store ./data-ds3 --http 18080 &
    
    # HTTPクライアントを受け入れるために --http (port) オプションを指定します

*spreadctl*コマンドを使ってクラスタの状態を確認してください。

    [localhost] $ spreadctl localhost nodes
    nid            name                 address                location    rsid      state
      0             ds0         127.0.0.1:18900      subnet-127.000.000       0     active
      1             ds1         127.0.0.1:18901      subnet-127.000.000       0     active
      2             ds2         127.0.0.1:18902      subnet-127.000.000       1     active
      3             ds3         127.0.0.1:18903      subnet-127.000.000       1     active

これでHTTPクライアントを使ってSpreadOSDを利用する準備ができました。

    [localhost]$ curl -X POST -d 'data=value1&attrs={"test":"attr"}' http://localhost:18080/data/key1
    
    [localhost]$ curl -X GET http://localhost:18080/data/key1
    value1
    
    [localhost]$ curl -X GET http://localhost:18080/attrs/key1
    {"test":"attr"}
    
    [localhost]$ curl -X GET -d 'format=tsv' http://localhost:18080/attrs/key1
    test	attr

(TODO: See APIリファレンス)


## クラスタ構成

以下の例では、次のような6台のノードからなるクラスタを構成します：

TODO 図

    # node01, node02: Tokyo Tyrantをデュアルマスタ構成で起動します
    [on node01]$ mkdir /var/spread/mds1
    [on node01]$ ttserver /var/spread/mds1/db.tct -ulog /var/spread/mds1/ulog -sid 1 \
                          -mhost node02 -rts /var/spread/mds1/node02.rts
    
    [on node02]$ mkdir /var/spread/mds2
    [on node02]$ ttserver /var/spread/mds2/db.tct -ulog /var/spread/mds2/ulog -sid 2 \
                          -mhost node01 -rts /var/spread/mds2/node01.rts
    
    # node01: CSを起動します
    [on node01]$ mkdir /var/spread/cs
    [on node01]$ spread-cs --mds tt:node01--node02 -s /var/spread/cs
    
    # node03: DSを起動します（レプリケーション･セット 0）
    [on node03]$ mkdir /var/spread/node03
    [on node03]$ spread-ds --cs node01 --address node03 --nid 0 --rsid 0 \
                           --name node03 -s /var/spread/node03
    
    # node04: DSを起動します（レプリケーション･セット 0）
    [on node04]$ mkdir /var/spread/node04
    [on node04]$ spread-ds --cs node01 --address node04 --nid 1 --rsid 0 \
                           --name node04 -s /var/spread/node04
    
    # node05: DSを起動します（レプリケーション･セット 1）
    [on node05]$ mkdir /var/spread/node05
    [on node05]$ spread-ds --cs node01 --address node05 --nid 2 --rsid 1 \
                           --name node05 -s /var/spread/node05
    
    # node06: DSを起動します（レプリケーション･セット 1）
    [on node06]$ mkdir /var/spread/node06
    [on node06]$ spread-ds --cs node01 --address node06 --nid 3 --rsid 1 \
                           --name node06 -s /var/spread/node06
    
    # アプリケーションサーバ: GWを起動します
    [on app-svr]$ spread-gw --cs node01 --port 18800 --http 18080

*spreadctl*コマンドを使ってクラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

これで準備が整いました。HTTPクライアントを使うか、*spreadcli*コマンドを使って動作を確認してみてください。

    [on app-svr]$ echo val1 | spreadcli localhost add key1 - '{"type":"png"}'
    
    [on app-svr]$ spreadcli localhost get "key1"
    0.002117 sec.
    {"type":"png"}
    val1

TODO: See 運用


SpreadOSD 運用
==============

TODO

## DSの追加

### 新しいレプリケーション･セットを追加する

レプリケーション･セットを追加することで、ストレージの容量とI/O性能を向上させることができます。

まずはじめに、現在のクラスタの状態を確認してください：

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

新しいレプリケーション･セット用に2台以上のサーバを用意して、spread-dsコマンドを実行します。
ここでは、ID=2のレプリケーション･セットを"node07"と"node08"の２台のサーバを使って構成します：

    [on node07]$ mkdir /var/spread/node07
    [on node07]$ spread-ds --cs node01 --address node07 --nid 4 --rsid 2 \
                           --name node07 -s /var/spread/node07
    
    [on node08]$ mkdir /var/spread/node08
    [on node08]$ spread-ds --cs node01 --address node08 --nid 5 --rsid 2 \
                           --name node08 -s /var/spread/node08

最後にクラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active
      4          node07       192.168.0.17:18900      subnet-192.168.000       2     active
      5          node08       192.168.0.18:18900      subnet-192.168.000       2     active

TODO: See: Changing weight of load balancing


### 既存のレプリケーション･セットにサーバを追加する

既存のレプリケーション･セットにサーバを追加することで、耐障害性とread性能を向上させることができます。

まずはじめに、現在のクラスタの状態を確認してください：

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

ここではID=0のレプリケーション･セットにサーバを追加します。

新しいサーバを用意して、レプリケーション･セット内の別のサーバからデータをコピーしてきます。

Prepare new server and copy existing data from other server on the replication-set using rsync:

    [on node07]$ mkdir /var/spread/node07
    
    # まずリレータイムスタンプをコピーする
    [on node07]$ scp node03:/var/spread/node03/rts-* /var/spread/node07/
    
    # データをrsyncを使ってコピーする
    #   rsyncのオプション:
    #     -a  アーカイブモード
    #     -v  verboseモード
    #     -e  暗号化アルゴリズムを指定する
    #         arcfour128アルゴリズムは高速ですが脆弱なアルゴリズムです。
    #         もし安全なネットワークでない場合には "blowfish" アルゴリズムが良いでしょう。
    #     --bwlimit 帯域を制限します（単位はKB/s）
    [on node07]$ rsync -av -e 'ssh -c arcfour128' --bwlimit 32768 \
                       node03:/var/spread/node03/data /var/spread/node07/

データをコピーし終わったら、spread-dsコマンドを実行してください。

    [on node07]$ spread-ds --cs node01 --address node07 --nid 4 --rsid 0 \
                           --name node07 -s /var/spread/node07

最後にクラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active
      4          node07       192.168.0.17:18900      subnet-192.168.000       0     active

TODO: See HowTo Geo-redundancy


## DSの離脱

データサーバを離脱させてクラスタの規模を縮小することができます。

まずはじめに、現在のクラスタの状態を確認してください：

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

DSのプロセスを終了させます：

    [on node04]$ kill `pidof spread-ds`

クラスタの状態は次のようになります：

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     FAULT
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

**spreadctl** **remove_node**コマンドを実行します：

    $ spreadctl node01 remove_node 1

最後にクラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active


## 重みの設定

TODO

    $ spreadctl node01 weight
    rsid   weight       nids   names
       0       10        0,1   node3,node4
       1       10        2,3   node5,node6

    $ spreadctl node01 set_weight 0 5

    $ spreadctl node01 weight
    rsid   weight       nids   names
       0        5        0,1   node3,node4
       1       10        2,3   node5,node6


## 負荷の監視

TODO

    $ spreadtop node01

Type 's' to toggle short mode.


## バックアップ

TODO

### バックアップするべき項目

TODO

### クラスタ情報のバックアップ

TODO

### データのバックアップ

TODO

### メタデータのバックアップ

TODO




SpreadOSD 障害対応
==================

TODO

## DSの復旧

### データが失われていない場合

### データが失われた場合


## CSの復旧

### データが失われていない場合

### データが失われた場合


## GWの復旧



SpreadOSD コマンドラインリファレンス
====================================

TODO

## サーバコマンド

### spread-cs: Configuration Server

TODO

### spread-ds: Data Server

TODO

### spread-gw: Gateway

TODO


## 運用ツール

### spreadctl: 管理ツール

TODO

### spreadcli: コマンドラインクライアント

TODO

### spreadtop: 'top'風の監視ツール

TODO


SpreadOSD APIリファレンス
========================

## HTTP API

TODO


## MessagePack-RPC API

TODO




SpreadOSD 改善とデバッグ
========================

TODO



Upstartを使ってサーバプロセスを管理する - SpreadOSD HowTo
=========================================================

TODO


X-Accel-Redirectと組み合わせたシステム構築 - SpreadOSD HowTo
===========================================================

TODO


Tokyo Tyrant MDS の冗長化 - SpreadOSD HowTo
=========================================

TODO


データセンタをまたいだレプリケーション - SpreadOSD HowTo
=======================================================

TODO

MUNINを使って負荷を可視化する - SpreadOSD HowTo
===============================================

TODO


Nagiosを使って負荷を可視化する - SpreadOSD HowTo
================================================

TODO



