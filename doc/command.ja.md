SpreadOSD コマンドラインリファレンス
====================================

<!--
TODO
-->

## サーバコマンド

### spread-cs: Configuration Server

    Usage: spread-cs [options]
        -p, --port PORT                  listen port
        -l, --listen HOST                listen address
        -m, --mds ADDRESS                address of metadata server
        -M, --mds-cache EXPR             mds cache
        -s, --store PATH                 path to base directory
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --weight_store PATH          path to weight status file
        -o, --log PATH
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log

#### -p, --port PORT

待ち受けるポート番号を指定します。デフォルトは18700です。

#### -l, --listen HOST

待ち受けるアドレスを指定します。デフォルトは0.0.0.0（すべてのアドレス）です。

#### -m, --mds ADDRESS

MDS (Metadata Server) のアドレスを指定します。
アドレスは *SCHEME:EXPRESSION* の形式になります。

次のSCHEMEをサポートしています：tt

#### -m, --mds tt:EXPRESSION

MDSにTokyo Tyrantを使用します。
EXPRESSIONには、単一のサーバ、マスタとスレーブ、またはデュアルマスタを指定することができます。

単一のサーバを使用する場合は、*host:port* の形式で指定してください。

マスタとスレーブを使用する場合は、*host1:port1,host2:port2,...* の形式で指定してください。参照の重みを指定するには、*host1:port1,host2:port2,...;weight1,weight2,...* の形式で指定ください。

例えば、1台のマスタと2台のスレーブでレプリケーションし、マスタからは参照を行わず、2台のスレーブに均等に参照を割り振るには、*tt:host1:port,host2:port2,host3:port3;0,1,1* と指定してください。

デュアルマスタを使用する場合は、*host1:port1--host2:port2* の形式で指定してください。

<!--
#### -s, --store PATH

TODO
-->


### spread-gw: Gateway

    Usage: spread-gw [options]
        -c, --cs ADDRESS                 address of config server
        -p, --port PORT                  listen port
        -l, --listen HOST                listen address
        -t, --http PORT                  http listen port
            --http-error-page PATH       path to eRuby template file
        -R, --read-only                  read-only mode
        -N, --read-only-name NAME        read-only mode using the version name
        -T, --read-only-time TIME        read-only mode using the time
        -L, --location STRING            enable location-aware master selection
        -s, --store PATH                 path to base directory
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --weight_store PATH          path to weight status file
        -o, --log PATH
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log

#### -c, --cs ADDRESS

CS (Configuration Server) のアドレスを指定します。

<!--
#### -L, --location STRING

TODO

#### -t, --http PORT

TODO

#### --http-error-page PATH

TODO

#### --http-redirect-port PORT

TODO

#### --http-redirect-path PATH

TODO

#### -R, --read-only

TODO

#### -T, --read-only-time TIME

TODO
-->


### spread-ds: Data Server

DSはGWの機能と同じ機能を持っているため、重複する引数があります。

    Usage: spread-ds [options]
        -c, --cs ADDRESS                 address of config server
        -i, --nid ID                     unieque node id
        -n, --name NAME                  node name
        -a, --address ADDRESS[:PORT]     address of this node
        -l, --listen HOST[:PORT]         listen address
        -g, --rsid IDs                   replication set IDs
        -L, --location STRING            location of this node
        -s, --store PATH                 path to storage directory
        -u, --ulog PATH                  path to update log directory
        -r, --rts PATH                   path to relay timestamp directory
        -t, --http PORT                  http listen port
            --http-error-page PATH       path to eRuby template file
            --http-redirect-port PORT
            --http-redirect-path FORMAT
        -R, --read-only                  read-only mode
        -N, --read-only-name NAME        read-only mode using the version name
        -T, --read-only-time TIME        read-only mode using the time
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
        -o, --log PATH
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log

#### -c, --cs ADDRESS

CS (Configuration Server) のアドレスを指定します。

#### -i, --nid ID

このサーバの一意な識別子を整数で指定します。

#### -n, --name NAME

このサーバの名前を指定します。この名前は管理ツールで使われます。

#### -a, --address ADDRESS

このサーバのアドレスを指定します。このサーバは、ここで指定したアドレスでアクセスされます。

#### -g, --rsid RSIDs

このサーバが参加するレプリケーション･セットの識別子を指定します。

<!--
#### -L, --location STRING

TODO

#### -s, --store PATH

TODO
-->


## 運用ツール

### spreadctl: 管理ツール

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       stat                         show statistics of nodes
       nodes                        show list of nodes
       remove_node <nid>            remove a node from the cluster
       weight                       show list of replication sets
       set_weight <rsid> <weight>   set distribution weight
       mds                          show MDS uri
       set_mds <URI>                set MDS uri
       items                        show stored number of items
       version                      show software version of nodes
       locate <key>                 show which servers store the key

<!--
TODO
-->


### spreadcli: コマンドラインクライアント

    Usage: spreadcli <cs address[:port]> <command> [options]
    command:
       get <key>                           get data and attributes
       gett <time> <key>                   get data and attributes using the time
       getv <vname> <key>                  get data and attributes using the version name
       get_data <key>                      get data
       gett_data <time> <key>              get data using the time
       getv_data <vname> <key>             get data using the version name
       get_attrs <key>                     get attributes
       gett_attrs <time> <key>             get attributes using the time
       getv_attrs <vname> <key>            get attributes using the version name
       read <key> <offset> <size>          get data with the offset and the size
       readt <time> <key> <offset> <size>  get data with the offset and the size using version time
       readv <vname> <key> <offset> <size> get data with the offset and the size using version name
       add <key> <data> <json>             set data and attributes
       addv <vname> <key> <data> <json>    set data and attributes with version name
       add_data <key> <data>               set data
       addv_data <vname> <key> <data>      set data with version name
       update_attrs <key> <json>           update attributes
       delete <key>                        delete the data and attributes
       deletet <time> <key>                delete the data and attributes using the time
       deletev <vname> <key>               delete the data and attributes using the version name
       remove <key>                        remove the data and attributes

<!--
TODO
-->


### spreadtop: 'top'風の監視ツール

    Usage: spreadtop <cs address>


