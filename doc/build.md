Cluster construction - SpreadOSD
================================

It describes how to construct the SpreadOSD cluster in this document.

## Running on single host

You can try to use SpreadOSD on single host as follows:

    # 1. Runs metadata server (Tokyo Tyrant).
    #    It runs single node in this tutorial.
    [localhost]$ ttserver mds.tct &
    
    # 2. Runs configuration server (CS).
    #    CS requires --mds (address of MDS) option and -s (configuration directory) option.
    [localhost]$ mkdir data-cs
    [localhost]$ spread-cs --mds 127.0.0.1 -s ./data-cs &
    
    # 3. Runs data server (DS).
    #    DS requires following options:
    #      --cs (address of CS)
    #      --address (address of this node)
    #      --nid (unique node ID)
    #      --rsid (ID of replication-set to join)
    #      --name (human-friendly node name)
    #      --store (storage path)
    [localhost]$ mkdir data-ds0
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18900 --nid 0 --rsid 0 \
                           --name ds0 --store ./data-ds0 &
    
    # 4. Runs data servers...
    [localhost]$ mkdir data-ds1
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18901 --nid 1 --rsid 0 \
                           --name ds1 --store ./data-ds1 &
    
    [localhost]$ mkdir data-ds2
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18902 --nid 2 --rsid 1 \
                           --name ds2 --store ./data-ds2 &
    
    [localhost]$ mkdir data-ds3
    [localhost]$ spread-ds --cs 127.0.0.1 --address 127.0.0.1:18903 --nid 3 --rsid 1 \
                           --name ds3 --store ./data-ds3 --http 18080 &
    
    # Use --http (port) option to accept HTTP client.

Confirm status of the cluster using *spreadctl* command.

    [localhost] $ spreadctl localhost nodes
    nid            name                 address                location    rsid      state
      0             ds0         127.0.0.1:18900      subnet-127.000.000       0     active
      1             ds1         127.0.0.1:18901      subnet-127.000.000       0     active
      2             ds2         127.0.0.1:18902      subnet-127.000.000       1     active
      3             ds3         127.0.0.1:18903      subnet-127.000.000       1     active

It is prepared to use SpreadOSD with HTTP client.

    [localhost]$ curl -X POST -d 'data=value1&attrs={"test":"attr"}' http://localhost:18080/data/key1
    
    [localhost]$ curl -X GET http://localhost:18080/data/key1
    value1
    
    [localhost]$ curl -X GET http://localhost:18080/attrs/key1
    {"test":"attr"}
    
    [localhost]$ curl -X GET -d 'format=tsv' http://localhost:18080/attrs/key1
    test	attr

Next step：[API Reference](api.md)


## Running on cluster

It runs runs 6-node cluster in following tutorial:

TODO figure

    # node01 and node02: run two Tokyo Tyrant servers as dual-master.
    [on node01]$ mkdir /var/spread/mds1
    [on node01]$ ttserver /var/spread/mds1/db.tct -ulog /var/spread/mds1/ulog -sid 1 \
                          -mhost node02 -rts /var/spread/mds1/node02.rts
    
    [on node02]$ mkdir /var/spread/mds2
    [on node02]$ ttserver /var/spread/mds2/db.tct -ulog /var/spread/mds2/ulog -sid 2 \
                          -mhost node01 -rts /var/spread/mds2/node01.rts
    
    # node01: runs CS.
    [on node01]$ mkdir /var/spread/cs
    [on node01]$ spread-cs --mds tt:node01--node02 -s /var/spread/cs
    
    # node03: runs DS for replication-set 0.
    [on node03]$ mkdir /var/spread/node03
    [on node03]$ spread-ds --cs node01 --address node03 --nid 0 --rsid 0 \
                           --name node03 -s /var/spread/node03
    
    # node04: runs DS for replication-set 0.
    [on node04]$ mkdir /var/spread/node04
    [on node04]$ spread-ds --cs node01 --address node04 --nid 1 --rsid 0 \
                           --name node04 -s /var/spread/node04
    
    # node05: runs DS for replication-set 1.
    [on node05]$ mkdir /var/spread/node05
    [on node05]$ spread-ds --cs node01 --address node05 --nid 2 --rsid 1 \
                           --name node05 -s /var/spread/node05
    
    # node06: runs DS for replication-set 1.
    [on node06]$ mkdir /var/spread/node06
    [on node06]$ spread-ds --cs node01 --address node06 --nid 3 --rsid 1 \
                           --name node06 -s /var/spread/node06
    
    # on application server: runs a GW.
    [on app-svr]$ spread-gw --cs node01 --port 18800 --http 18080

Confirm status of the cluster using *spreadctl* command.

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

Now the cluster is active. Try to set and get using http client, or *spreadcli* command as follows:

    [on app-svr]$ echo val1 | spreadcli localhost add key1 - '{"type":"png"}'
    
    [on app-svr]$ spreadcli localhost get "key1"
    0.002117 sec.
    {"type":"png"}
    val1

Note that you can't change the IP address of the configuration server.
In other words, the address becomes identifier of a cluster.

It is good idea to set exclusive IP alias for the address:

    [on node01]$ ifconfig eth0:0 192.168.0.254
    [on node01]$ spread-cs --mds tt:node01--node02 -s /var/spread/cs \
                           -l 192.168.0.254

Next step: [Operations](operation.md)

