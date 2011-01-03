SpreadOSD
=========
SpreadOSD - 分散ストレージシステム


## 概要

SpreadOSDは、画像、音声、動画などの大きなデータを保存するのに適した、分散ストレージシステムです。

サーバを追加することで容量を動的に増加させることができます。
レプリケーションをサポートし、極めて短いダウンタイムでフェイルオーバーします。


## アーキテクチャ

SpreadOSDは、次の4種類のサーバから構成されます：

  - **DS (data server)** は、コンテンツをディスク上に保存したりレプリケーションしたりします。
  - **MDS (metadata server)** は、コンテンツのメタデータを保存します。メタデータにはコンテンツがどのDSに保存されているかを示す情報も含まれています。MDSには[Tokyo Tyrant](http://fallabs.com/tokyotyrant/)を使います。
  - **GW (gateway)** は、アプリケーションからの要求を受け取り、適切なDSに中継します。
  - **CS (config server)** は、クラスタの設定情報を管理します。また、DSの状態を監視し、故障したDSを自動的に切り離します。

**レプリケーション･セット**は、複数のDSで構成されるグループです。同じレプリケーション･セットに属するDSは、同じデータをレプリケーションして保存しています。


                        App     App     App
                         |       |       |  MessagePack-RPC
            ----------- GW      GW      GW
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


## インストール

以下のソフトウェアが必要です：

  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) >= 1.1.40
  - [ruby](http://www.ruby-lang.org/) >= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) >= 0.4.3
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) >= 1.13

./configure && make install のいつもの方法でインストールしてください：

    $ ./bootstrap  # 必要な場合
    $ ./configure
    $ make
    $ sudo make install

rake と gem を使ってインストールすることもできます。

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

次のコマンドがインストールされます：

  - spreadctl: 管理ツール
  - spreadcli: コマンドラインクライアント
  - spread-cs: CS
  - spread-ds: DS
  - spread-gw: GW


### フルインストールガイド

まず以下のパッケージをインストールしてください。

  - gcc-g++ >= 4.1
  - openssl-devel (or libssl-dev) to build ruby
  - zlib-devel (or zlib1g-dev) to build ruby
  - readline-devel (or libreadline6-dev) to build ruby

以下の手順でSpreadOSDを/opt/local/spreadにインストールできます。

    # Tokyo Tyrantをインストール
    $ wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz
    $ tar zxvf tokyotyrant-1.1.41.tar.gz
    $ cd tokyotyrant-1.1.41
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # ruby-1.9をインストール
    $ wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p0.tar.bz2
    $ tar jxvf ruby-1.9.2-p0.tar.bz2
    $ cd ruby-1.9.2
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # 必要なgemをインストール
    $ sudo /opt/local/spread/bin/gem install msgpack-rpc
    $ sudo /opt/local/spread/bin/gem install tokyotyrant
    
    # SpreadOSDをインストール
    $ git clone http://github.com/frsyuki/spread.git
    $ cd spread
    $ ./configure RUBY=/opt/local/spread/bin/ruby --prefix=/opt/local/spread
    $ make
    $ sudo make install


## チュートリアル

以下の例では、6台のノードからなるクラスタを構成します：

    # デュアルマスタ構成の Tokyo Tyrant サーバを起動
    [on node01]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 1 \
                          -mhost node02 -rts /var/spread/sid1.rts
    [on node02]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 2 \
                          -mhost node01 -rts /var/spread/sid2.rts
    
    # CSを起動
    [on node01]$ spread-cs --mds node01,node02 -s /var/spread
    
    # レプリケーション･セット0のDSを起動
    [on node03]$ spread-ds --cs node03 --address node03 --nid 0 --rsid 0 \
                           --name mynode03 --storage /var/spread
    [on node04]$ spread-ds --cs node04 --address node04 --nid 1 --rsid 0 \
                           --name mynode04 --storage /var/spread
    
    # レプリケーション･セット1のDSを起動
    [on node05]$ spread-ds --cs node05 --address node05 --nid 2 --rsid 1 \
                           --name mynode05 --storage /var/spread
    [on node06]$ spread-ds --cs node06 --address node06 --nid 3 --rsid 1 \
                           --name mynode06 --storage /var/spread
    
    # アプリケーションサーバ上でGWを起動
    [on client]$ spread-gw --cs node01 --port 18800

*spreadctl*コマンドを使って、クラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

これでクラスタが使えるようになりました。*spredcli*コマンドを使ってset/getしてみてください。

    # localhostでGWが動作している
    [on client]$ spreadcli 127.0.0.1 set "key1" '{"type":"png","data":"..."}'
    true
    
    [on client]$ spreadcli 127.0.0.1 get "key1"
    {"type":"png","data":"..."}


### 1台のホスト上で動かす

以下のようにして1台のホスト上でSpreadOSDを動かし、テストすることができます：

    [localhost]$ ttserver mds.tct
    [localhost]$ spread-cs --mds 127.0.0.1 -s ./data-cs
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18900 --nid 0 --rsid 0 \
                           --name ds0 --storage ./data-ds0
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18901 --nid 1 --rsid 0 \
                           --name ds1 --storage ./data-ds1
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18902 --nid 2 --rsid 1 \
                           --name ds2 --storage ./data-ds2
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18903 --nid 3 --rsid 1 \
                           --name ds3 --storage ./data-ds3
    [localhost]$ spread-gw --cs 127.0.0.1



## クラスタの管理

### 新しいDSを追加する

まず*spreadct*コマンドを使って、クラスタの状態を確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

次に新しいサーバを起動してください。

最後にクラスタの状態を確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active
      4        mynode07      192.168.0.17:18900         2     active
      5        mynode08      192.168.0.18:18900         2     active

必要に応じて負荷分散の**重み**を設定してください。


### 負荷分散の重みを変更する

レプリケーション･セットには、新しいデータをどのレプリケーション･セットを保存するかを決める**重み**を指定することができます。デフォルトの重みは10です。

あるレプリケーション･セットは、**そのレプリケーション･セットの重み / すべての重みの総和** の確率で選択されます。

重みを0にすると、そのレプリケーション･セットに新しいデータは保存されなくなります。

重みを変更するには、*spreadctl*コマンドを使います。

    $ spreadctl csaddr replset
    replset   weight       nids  names
          0       10        0,1  mynode03,mynode04
          1       10        2,3  mynode03,mynode06
          2       10        4,5  mynode07,mynode08

    $ spreadctl csaddr set_weight 0 5
    $ spreadctl csaddr set_weight 1 5

    $ spreadctl csaddr replset
    replset   weight       nids  names
          0        5        0,1  mynode03,mynode04
          1        5        2,3  mynode03,mynode06
          2       10        4,5  mynode07,mynode08


### 故障したDSを復旧する

もしDSが故障したら、そのサーバの状態は**FAULT**になります。まずそれを*spreadctl*コマンドを使って確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

#### データが失われていない場合

落ちたプロセスを再起動させてください。このとき、*--nid*オプションと*--rsid*オプションは落ちる前と同じにしてください。

状態が**active**に戻っていることを確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

#### データが失われている場合

まず、故障したサーバを切り離してください：

    $ spreadctl csaddr remove_node 2

次に、同じレプリケーション･セット内の別のDSからデータをコピーしてください。例えばrsyncを次のように実行します：

    # node03から現在のリレー状態ログをコピーする
    [on node07]$ scp node03:/var/spread/rlog-* /var/spread/
    
    # node03からリレー状態ログと更新ログ以外のデータをコピーする
    # rsyncのオプション:
    #   -a  アーカイブモード
    #   -v  verbose
    #   -e  sshでarcfour128アルゴリズムを使う
    #       arcfour128アルゴリズムは高速ですが、強度が低いことに注意してください。
    #       安全なネットワーク以外では、"blowfish"を使ってください。
    #   --bwlimit 帯域をKB/s単位で制限する
    [on node07]$ rsync -av -e 'ssh -c arcfour128' --exclude "ulog-*" --exclude "rlog-*" \
                       --bwlimit 32768 node03:/var/spread/ /var/spread/
    
    # 更新ログは削除しておく
    [on node07]$ rm -f /var/spread/ulog-*

このときにコピー元のノード（この例ではnode03）を停止させる必要はありません。

次に、*--rsid*オプションを故障したサーバと同じにした状態で、新しいサーバを起動してください。*--nid*オプションには必ず新しい番号を割り当ててください。

最後にクラスタの状態を確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active
      4        mynode07      192.168.0.17:18900         0     active


### 故障したDSを切り離す

もしDSが故障したら、そのサーバの状態は**FAULT**になります。まずそれを*spreadctl*コマンドを使って確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

サーバを復旧するのではなく切り離したい場合は、次のようにコマンドを実行してください：

    $ spreadctl csaddr remove_node 2

最後にクラスタの状態を確認してください。

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active


### 故障したCSを復旧する

CSは単に再起動してください。

CSは、クラスタの状態を"$storage_path/membership"ファイルと"$storage_path/fault"ファイルに保存しています。

もしmembershipファイルが失われた場合は、状態が**FAULT**であるサーバは切り離されます。
もしfaultファイルが失われた場合は、状態が**FAULT**であるサーバは**active**になり、タイムアウト時間が経過した後で**FAULT**に戻ります。

もしそれらのDSを復旧する場合は、CSを復旧する前にDSを復旧させてください。


### 落ちたGWを復旧する

GWはステートレスなサーバです。単に再起動してください。



## プロトコル

SpreadOSDは、クライアントプロトコルに[MessagePack-RPC](http://msgpack.org/)を使います。

クライアントアプリケーションは以下のコマンドを利用することができます：

### get(key:Raw) -> map:Map<Raw,Raw>
mapを取得します。

成功した場合は見つかったmapを返します。そうでなければ空のmapを返します。


### set(key:Raw, map:Map<Raw,Raw>) -> success:Boolean
mapを保存します。"data"という名前のカラムはDSに保存されます。それ以外のカラムはMDSに保存されます。

成功した場合はtrueを返します。そうでなければfalseを返します。


### remove(key:Raw) -> success:Boolean
mapを削除します。

成功した場合はtrueを返します。そうでなければfalseを返します。


### get_direct(key:Raw, rsid:Integer) -> data:Raw or nil
データを取得します。このコマンドはMDSにアクセスしません。

成功した場合は見つかったデータを返します。そうでなければfalseを返します。


### set_direct(key:Raw, data:Raw, rsid:Integer) -> success:Boolean
データを保存します。このコマンドはMDSにアクセスしません。

成功した場合はtrueを返します。そうでなければfalseを返します。


### remove_direct(key:Raw, rsid:Integer) -> succeeded:Boolean
データを削除します。このコマンドはMDSにアクセスしません。

成功した場合はtrueを返します。そうでなければfalseを返します。



## リファレンス

### spreadctl

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       nodes                        ノード一覧表を表示
       replset                      レプリケーション･セットの一覧表を表示
       stat                         統計情報を表示
       items                        保存されているデータの数を表示
       remove_node <nid>            ノードをクラスタから取り除く
       set_weight <rsid> <weight>   負荷分散の重みを指定


### spreadcli

    Usage: spreadcli <cs address[:port]> <command> [options]
    command:
       set <key> <json>                 mapを保存する
       get <key>                        mapを取得してJSON形式で表示する
       remove <key>                     mapを削除する
       get_data <key>                   mapを取得してmap["data"]を表示する
       set_data <key> <data>            {"data":data}を保存する
       get_direct <rsid> <key>          データを指定したレプリケーション･セットから直接取得する
       set_direct <rsid> <key> <data>   データを指定したレプリケーション･セットに直接保存する
       remove_direct <rsid> <key>       データを指定したレプリケーション･セットから直接削除する


### spread-cs

    Usage: spread-cs [options]
        -p, --port PORT                  ポート番号
        -s, --storage PATH               規定のディレクトリ
        -f, --fault_path PATH            落ちたノードを記録するファイルのパス
        -b, --membership PATH            ノード一覧表を記録するファイルのパス
        -t, --mds ADDRESS                メタデータサーバのアドレス


### spread-ds

    Usage: spread-ds [options]
        -i, --nid ID                     一意なノードID
        -n, --name NAME                  ノードの名前
        -a, --address ADDRESS            このサーバのアドレス
        -g, --rsid IDs                   レプリケーション･セットのID
        -s, --storage PATH               ストレージのディレクトリ
        -u, --ulog PATH                  更新ログを保存するディレクトリ
        -r, --rlog PATH                  リレー状態ログを保存するディレクトリ
        -m, --cs ADDRESS                 config serverのアドレス
        -f, --fault_path PATH            落ちたノードを記録するファイルのパス
        -b, --membership PATH            ノード一覧表を記録するファイルのパス


### spread-gw

    Usage: spread-gw [options]
        -p, --port PORT                  ポート番号
        -m, --cs ADDRESS                 config serverのアドレス
        -s, --storage PATH               規定のディレクトリ
        -f, --fault_path PATH            落ちたノードを記録するファイルのパス
        -b, --membership PATH            ノード一覧表を記録するファイルのパス



## ソースコードの改変

SpreadOSDはオープンソフトウェアです。ソースコードを改変することができます。

### Source tree

    lib/spread-osd
    |
    +-- mds/                  メタデータサーバのクライアントの実装
    |   |
    |   +-- base.rb
    |   +-- tokyotyrant.rb    Tokyo Tyrantのクライアント実装
    |   +-- astt.rb           Tokyo Tyrantのクライアント実装の非同期版
    |
    +-- storage/              データサーバのストレージ実装
    |   |
    |   +-- base.rb
    |   +-- hash.rb           Hashベースのオンメモリのストレージ
    |   +-- file.rb           ファイルベースのストレージ
    |
    +-- rlog/                 データサーバのリレー状態ログの実装
    |   |
    |   +-- base.rb
    |   +-- memory.rb         オンメモリのリレー状態ログ
    |   +-- file.rb           ファイルベースのリレー状態ログ
    |
    +-- ulog/                 データサーバの更新ログの実装
    |   |
    |   +-- base.rb
    |   +-- array.rb          Arrayベースのオンメモリの更新ログ
    |   +-- file.rb           ファイルベースの更新ログ
    |
    +-- lib/                  基本的なライブラリ群
    |   |
    |   +-- ebus.rb           EventBus
    |   +-- cclog.rb          ログ
    |   +-- vbcode.rb         Variable byte code
    |
    +-- logic/
    |   |
    |   +-- node.rb                     Nodeクラスの実装
    |   +-- fault_detector.rb           障害検出
    |   +-- membership.rb               ノード一覧表とレプリケーション･セットの一覧表
    |   +-- weight.rb                   負荷分散
    |   +-- storage_manager.rb          ストレージインタフェース
    |   +-- master_storage_manager.rb   スレーブサーバ用のストレージインタフェース
    |   +-- slave_storage_manager.rb    マスタサーバ用のストレージインタフェース
    |
    +-- service/
    |   |
    |   +-- base.rb
    |   +-- net.rb
    |   +-- timer.rb
    |   |
    |   +-- mds.rb
    |   |
    |   +-- storage.rb
    |   +-- storage_client.rb
    |   |
    |   +-- gateway.rb
    |   +-- heartbeat.rb
    |   +-- membership.rb
    |   |
    |   +-- status.rb
    |   +-- cs_status.rb
    |   +-- ds_status.rb
    |   +-- gw_status.rb
    |   |
    |   +-- config.rb
    |   +-- cs_config.rb
    |   +-- ds_config.rb
    |   +-- gw_config.rb
    |   |
    |   +-- cs_rpc.rb
    |   +-- ds_rpc.rb
    |   +-- gw_rpc.rb
    |
    +-- comand/
    |
    +-- bus.rb                EventBusのスロットの宣言
    |
    +-- default.rb            デフォルトのポート番号などの定数
    |
    +-- common.rb


## License

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

