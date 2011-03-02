Commandline reference - SpreadOSD
=================================

<!--
TODO
-->

## Server commands

### spread-cs: configuration server

    Usage: spread-cs [options]
        -p, --port PORT                  listen port
        -l, --listen HOST                listen address
        -m, --mds EXPR                   address of metadata server
        -M, --mds-cache EXPR             mds cache
        -s, --store PATH                 path to base directory
            --fault_store PATH           path to fault status file
            --membership_store PATH      path to membership status file
            --weight_store PATH          path to weight status file
        -o, --log PATH
        -v, --verbose                    show debug messages
            --trace                      show debug and trace messages
            --color-log                  force to enable color log


### spread-gw: gateway

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


### spread-ds: data server

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


## Operation tools

### spreadctl: control tool

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       stat                         show statistics of nodes
       nodes                        show list of nodes
       remove_node <nid>            remove a node from the cluster
       weight                       show list of replication sets
       set_weight <rsid> <weight>   set distribution weight
       mds                          show MDS uri
       set_mds <URI>                set MDS uri
       mds_cache                    show MDS cache uri
       set_mds_cache <URI>          set MDS cache uri
       items                        show stored number of items
       version                      show software version of nodes
       locate <key>                 show which servers store the key

### spreadcli: command line client

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

### spreadtop: monitoring tool like 'top'

    Usage: spreadtop <cs address>


