Operations - SpreadOSD
======================

TODO

## Adding data servers

### Creating a new replication-set

By creating new replication-set, both storage capacity and I/O performance grow.

First of all, confirm current status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

Prepare 2 or more servers for the new replication-set and run spread-ds command on the servers.
In this process, we'll create replication-set (ID=2) with 2 servers named "node07" and "node08":

    [on node07]$ mkdir /var/spread/node07
    [on node07]$ spread-ds --cs node01 --address node07 --nid 4 --rsid 2 \
                           --name node07 -s /var/spread/node07
    
    [on node08]$ mkdir /var/spread/node08
    [on node08]$ spread-ds --cs node01 --address node08 --nid 5 --rsid 2 \
                           --name node08 -s /var/spread/node08

Finally, confirm the status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active
      4          node07       192.168.0.17:18900      subnet-192.168.000       2     active
      5          node08       192.168.0.18:18900      subnet-192.168.000       2     active

See: Changing weight of replication-sets


### Adding a server to existing replication-set

By adding a server to existing replication-set, you can raise availability and read performance of the replication-set.

First of all, confirm current status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

In this process, we'll add a server to replication-set whose ID is 0.

Prepare new server and copy existing data from other server on the replication-set using rsync.

    [on node07]$ mkdir /var/spread/node07
    
    # Copy relay time stamps first
    [on node07]$ scp node03:/var/spread/node03/rts-* /var/spread/node07/
    
    # Copy data using rsync.
    #   rsync option:
    #     -a  Archive mode
    #     -v  Verbose mode
    #     -e  Set cipher algorithm.
    #         Note that arcfour128 is fast but weak algorithm only for secure network.
    #         "blowfish" is good choice if the network is insecure.
    #     --bwlimit limits bandwidth in KB/s
    [on node07]$ rsync -av -e 'ssh -c arcfour128' --bwlimit 32768 \
                       node03:/var/spread/node03/data /var/spread/node07/

After data is copied, run a DS process.

    [on node07]$ spread-ds --cs node01 --address node07 --nid 4 --rsid 0 \
                           --name node07 -s /var/spread/node07

Finally, confirm the status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active
      4          node07       192.168.0.17:18900      subnet-192.168.000       0     active

<!--
TODO: See HowTo Geo-redundancy
-->


## Removing a data server

You can remove data servers from a replication-set. Note that you can't remove replication-sets.

First of all, confirm current status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

Terminate a DS process:

    [on node04]$ kill `pidof spread-ds`

Status of the cluster becomes as follows:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     FAULT
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

Then, run **spreadctl** **remove_node** command:

    $ spreadctl node01 remove_node 1

Finally, confirm the status of the cluster:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active


## Changing weight of replication-sets

<!--
TODO
-->

    $ spreadctl node01 weight
    rsid   weight       nids   names
       0       10        0,1   node3,node4
       1       10        2,3   node5,node6

    $ spreadctl node01 set_weight 0 5

    $ spreadctl node01 weight
    rsid   weight       nids   names
       0        5        0,1   node3,node4
       1       10        2,3   node5,node6


## Monitoring load

<!--
TODO
-->

    $ spreadtop node01

Type 's' to toggle short mode.


<!--
## Backup

TODO

### Items to backup

TODO

### Backup cluster information

TODO

### Backup data

TODO

### Backup metadata

TODO
-->


Next step: [Fault management](fault.md)

