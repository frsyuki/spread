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
  - [rack gem](http://rubygems.org/gems/rack) >= 1.2.1

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

このガイドでは、システム全体を/opt/local/spreadディレクトリにインストールします。

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
    $ sudo /opt/local/spread/bin/gem install rack
    
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
                           --name mynode03 --store /var/spread
    [on node04]$ spread-ds --cs node04 --address node04 --nid 1 --rsid 0 \
                           --name mynode04 --store /var/spread
    
    # レプリケーション･セット1のDSを起動
    [on node05]$ spread-ds --cs node05 --address node05 --nid 2 --rsid 1 \
                           --name mynode05 --store /var/spread
    [on node06]$ spread-ds --cs node06 --address node06 --nid 3 --rsid 1 \
                           --name mynode06 --store /var/spread
    
    # アプリケーションサーバ上でGWを起動
    [on client]$ spread-gw --cs node01 --port 18800 --http 18080

*spreadctl*コマンドを使って、クラスタの状態を確認してください。

    $ spreadctl node01 nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

これでクラスタが使えるようになりました。*spredcli*コマンドを使ってset/getしてみてください。

    # localhostでGWが動作している
    [on client]$ spreadcli 127.0.0.1 set "key1" 'val1' '{"type":"png"}'
    
    [on client]$ spreadcli 127.0.0.1 get "key1"
    {"type":"png"}
    val1


### 1台のホスト上で動かす

以下のようにして1台のホスト上でSpreadOSDを動かし、テストすることができます：

    [localhost]$ ttserver mds.tct
    [localhost]$ spread-cs --mds 127.0.0.1 -s ./data-cs
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18900 --nid 0 --rsid 0 \
                           --name ds0 --store ./data-ds0
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18901 --nid 1 --rsid 0 \
                           --name ds1 --store ./data-ds1
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18902 --nid 2 --rsid 1 \
                           --name ds2 --store ./data-ds2
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18903 --nid 3 --rsid 1 \
                           --name ds3 --store ./data-ds3 --http 18080


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
    [on node07]$ scp node03:/var/spread/rts-* /var/spread/
    
    # node03からリレー状態ログと更新ログ以外のデータをコピーする
    # rsyncのオプション:
    #   -a  アーカイブモード
    #   -v  verbose
    #   -e  sshでarcfour128アルゴリズムを使う
    #       arcfour128アルゴリズムは高速ですが、強度が低いことに注意してください。
    #       安全なネットワーク以外では、"blowfish"を使ってください。
    #   --bwlimit 帯域をKB/s単位で制限する
    [on node07]$ rsync -av -e 'ssh -c arcfour128' --exclude "ulog-*" --exclude "rts-*" \
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

CSは、クラスタの状態を"$store_path/membership"ファイルと"$store_path/fault"ファイルに保存しています。

もしmembershipファイルが失われた場合は、状態が**FAULT**であるサーバは切り離されます。
もしfaultファイルが失われた場合は、状態が**FAULT**であるサーバは**active**になり、タイムアウト時間が経過した後で**FAULT**に戻ります。

もしそれらのDSを復旧する場合は、CSを復旧する前にDSを復旧させてください。


### 落ちたGWを復旧する

GWはステートレスなサーバです。単に再起動してください。



## Application interface

SpreadOSD uses [MessagePack-RPC](http://msgpack.org/) and HTTP as a client protocol.

### MessagePack-RPC


#### get(key:Raw) -> [data:Raw, attributes:Map<Raw,Raw>]
Gets data and attributes from the storage.

Returns the found data and attributes if it success. Otherwise, it returns [nil, nil].


#### get_data(key:Raw) -> data:Raw
Gets data from the storage.

Returns the found data if it success. Otherwise, it returns nil.


#### get_attrs(key:Raw) -> attributes:Map<Raw,Raw>
Gets attributes from the storage.

Returns the found attributes if it success. Otherwise, it returns nil.


#### gets(sid:Integer, key:Raw) -> [data:Raw, attributes:Map<Raw,Raw>]
Gets data and attributes from the storage using the snapshot.

Returns the found data and attributes if it success. Otherwise, it returns [nil, nil].


#### gets_data(sid:Integer, key:Raw) -> data:Raw
Gets data from the storage using the snapshot.

Returns the found data if it success. Otherwise, it returns nil.


#### gets_attrs(sid:Integer, key:Raw) -> attributes:Map<Raw,Raw>
Gets attributes from the storage using the snapshot.

Returns the found attributes if it success. Otherwise, it returns nil.


#### read(key:Raw, offset:Integer, size:Integer) -> data:Raw
Reads part of data from the storage.

Returns the found data if it success. Otherwise, it returns nil.


#### reads(sid:Integer, key:Raw, offset:Integer, size:Integer) -> data:Raw
Reads part of data from the storage using the snapshot.

Returns the found data if it success. Otherwise, it returns nil.


#### getd_data(objectKey:Object) -> data:Raw
Gets data from DS directly.

Returns the found data if it success. Otherwise, it returns nil.


#### readd(objectKey:Object, offset:Integer, size:Integer) -> data:Raw
Reads part of data from DS directly.

Returns the found data if it success. Otherwise, it returns nil.


#### set(key:Raw, data:Raw, attributes:Map<Raw,Raw>) -> objectKey:Object
Sets data and attributes to the storage.
The data is stored on DS, and the attributes are stored on MDS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### set_data(key:Raw, data:Raw) -> objectKey:Object
Sets data to the storage. The data is stored on DS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### set_attrs(key:Raw, attributes:Map<Raw,Raw>) -> objectKey:Object
Sets attributes to the storage. The attributes is stored on MDS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### write(key:Raw, offset:Integer, data:Raw) -> objectKey:Object
Writes part of data to the storage.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### remove(key:Raw)
Removes data and attributes from the storage.

Returns true if the object is removed. Otherwise, it returns false.


#### select(cols, conds, order, order_col, limit, skip) -> arrayOfAttributes:Array<Map<Raw,Raw>>

    cols:Array<String> or nil
    conds:Array<Condition>
    order:Integer or nil
    order_col:Raw or nil
    limit:Integer or nil
    skip:Integer or nil


#### selects(sid, cols, conds, order, order_col, limit, skip) -> arrayOfAttributes:Array<Map<Raw,Raw>>



### HTTP

TODO



## リファレンス

### spreadctl

**spreadctl** はクラスタの管理コマンドです。

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       nodes                        ノードの一覧を表示する
       replset                      レプリケーション･セットの一覧を表示する
       stat                         統計情報を表示する
       items                        保存されているデータの数を表示する
       remove_node <nid>            ノードをクラスタから取り除く
       set_weight <rsid> <weight>   負荷分散の重みを指定する
       snapshot                     スナップショットの一覧を表示する
       add_snapshot <name>          新しいスナップショットを追加する
       version                      各ノードのソフトウェアのバージョンを表示する


### spreadcli

**spreadcli** はコマンドラインのクライアントプログラムです。

    Usage: cli.rb <cs address[:port]> <command> [options]
    command:
       get_data <key>                     get data
       get_attrs <key>                    get attributes
       gets_data <sid> <key>              get data using the snapshot
       gets_attrs <sid> <key>             get attributes using the snapshot
       read <key> <offset> <size>         get data with the offset and the size
       reads <sid> <key> <offset> <size>  get data with the offset and the size
       set_data <key> <data>              set data
       set_attrs <key> <json>             set attributes
       write <key> <offset> <data>        set data with the offset and the size
       get <key>                          get data and attributes
       gets <sid> <key>                   get data and attributes using the snapshot
       set <key> <data> <json>            set data and attributes
       remove <key>                       remove the data
       select <expr> [cols...]            select attributes
       selects <sid> <expr> [cols...]     select attributes using the snapshot


### spread-cs

    Usage: spread-cs [options]
        -p, --port PORT                  listen port
        -m, --mds ADDRESS                address of metadata server
        -s, --store PATH                 path to base directory
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --snapshot_store PATH        path to snapshot status file
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log


### spread-ds

    Usage: spread-ds [options]
        -i, --nid ID                     unieque node id
        -n, --name NAME                  node name
        -a, --address ADDRESS            listen address
        -g, --rsid IDs                   replication set IDs
        -s, --store PATH                 path to storage directory
        -u, --ulog PATH                  path to update log directory
        -r, --rts PATH                   path to relay timestamp directory
        -t, --http                       http listen port
        -R, --read-only                  read-only mode
        -S, --snapshot SID               read-only mode using the snapshot
        -c, --cs ADDRESS                 address of config server
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --snapshot_store PATH        path to snapshot status file
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log


### spread-gw

    Usage: spread-gw [options]
        -p, --port PORT                  listen port
        -t, --http PORT                  http listen port
        -c, --cs ADDRESS                 address of config server
        -R, --read-only                  read-only mode
        -S, --snapshot SID               read-only mode using the snapshot
        -s, --store PATH                 path to base directory
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --snapshot_store PATH        path to snapshot status file
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log



## ソースコードの改変

SpreadOSDはオープンソフトウェアです。ソースコードを改変することができます。

### Source tree

    lib/spread-osd
    |
    +-- lib/                    基本的なライブラリ群
    |   |
    |   +-- ebus.rb             EventBus
    |   +-- cclog.rb            ログライブラリ
    |   +-- vbcode.rb           Variable byte code
    |
    +-- logic/
    |   |
    |   +-- node.rb             Nodeクラスの実装
    |   +-- tsv_data.rb         Tab separated dataを扱う基底クラス
    |   +-- fault_detector.rb   障害検出
    |   +-- membership.rb       ノード一覧表とレプリケーション･セットの一覧表
    |   +-- weight.rb           負荷分散
    |   +-- snapshot.rb         スナップショットの一覧表
    |
    +-- service/
    |   |
    |   +-- base.rb
    |   +-- bus.rb
    |   |
    |   +-- process.rb
    |   +-- heartbeat.rb
    |   +-- membership.rb
    |   +-- snapshot.rb
    |   |
    |   +-- data_server.rb
    |   +-- data_client.rb
    |   +-- slave.rb
    |   |
    |   +-- gateway.rb
    |   +-- gateway_ro.rb
    |   +-- gw_http.rb
    |   |
    |   +-- config.rb
    |   +-- config_cs.rb
    |   +-- config_ds.rb
    |   +-- config_gw.rb
    |   |
    |   +-- stat.rb
    |   +-- stat_cs.rb
    |   +-- stat_ds.rb
    |   +-- stat_gw.rb
    |   |
    |   +-- rpc.rb
    |   +-- rpc_cs.rb
    |   +-- rpc_ds.rb
    |   +-- rpc_gw.rb
    |   |
    |   +-- rts.rb
    |   +-- rts_file.rb
    |   +-- rts_memory.rb
    |   |
    |   +-- ulog.rb
    |   +-- ulog_file.rb
    |   +-- ulog_memory.rb
    |   |
    |   +-- mds.rb
    |   +-- mds_tt.rb
    |   |
    |   +-- storage.rb
    |   +-- storage_dir.rb
    |
    +-- command/
    |   |
    |   +-- ctl.rb              管理ツール
    |   +-- cs.rb               CS main
    |   +-- ds.rb               DS main
    |   +-- gw.rb               GW main
    |   +-- cli.rb              コマンドラインのクライアントプログラム
    |
    +-- default.rb              デフォルトのポート番号などの定数
    |
    +-- log.rb
    |
    +-- version.rb


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

