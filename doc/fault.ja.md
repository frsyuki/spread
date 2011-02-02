SpreadOSD 障害対応
==================

TODO

## DSの復旧

DS (Data Server) が故障すると、その状態が "FAULT" になります：

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     FAULT
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

DSを復旧する手順は、データが失われた（HDDが故障した）か失われていないか（プロセスがダウンした）によって異なります。

### データが失われていない場合

**--nid**引数と**--rsid**を変更せずに、サーバのプロセスを再起動してください。

故障したサーバと新しいサーバでは、ことなるIPアドレスを使うことができます。ただしその場合でもすべてのデータ（リレータイムスタンプファイル*rts-*\*と更新ログファイル*ulog-*\*を含む）を引き継いでください。

### データが失われた場合

もしデータが失われた場合は、そのサーバを取り除く必要があります。

    $ spreadctl node01 remove_node 1

この後で新しいノードを追加してください。
TODO: See Adding a server to existing replication-set


## CSの復旧

CSのIPアドレスは変更することができないので、故障したサーバと新しいサーバには同じIPアドレスを振る必要があります。あるいはCSに専用のIPエイリアスを割り当てているなら、そのIPエイリアスを新しいサーバに振ってください。

### データが失われていない場合

**--port**引数を変更せずに、spread-csプロセスを再起動してください。

### データが失われた場合

CSはクラスタの情報（*membership*ファイルと*fault*ファイル）を保存しています。実はこれらの情報は、他のノードにもキャッシュされています。
このため、まずそのキャッシュされた情報をDSやGWからコピーしてきてください：

    [on node01]$ mkdir /var/spread/cs
    [on node01]$ scp node03:/var/spread/node03/membership node03:/var/spread/node03/fault /var/spread/cs/

コピーが終わったら、spread-csプロセスを再起動してください。


## GWの復旧

GW (Gateway) は*ステートレス*なプロセスなので、単にプロセスを再起動すれば済みます。


