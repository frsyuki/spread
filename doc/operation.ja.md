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
    #         arcfour128アルゴリズムは高速ですが脆弱なアルゴリズムです
    #         もし安全なネットワークでない場合には "blowfish" アルゴリズムが良いでしょう
    #     --bwlimit 帯域を制限する（単位はKB/s）
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


次のステップ：[障害対応](fault.ja.md)

