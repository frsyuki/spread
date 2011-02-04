Fault management - SpreadOSD
============================

TODO

## Recovering data server

If a data server is crashed, its state becomes "FAULT" as follows:

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0          node03       192.168.0.13:18900      subnet-192.168.000       0     active
      1          node04       192.168.0.14:18900      subnet-192.168.000       0     FAULT
      2          node05       192.168.0.15:18900      subnet-192.168.000       1     active
      3          node06       192.168.0.16:18900      subnet-192.168.000       1     active

Recovering operation of the data servers is different depending on which data is lost (HDD is crashed) or not (process is down).

### If data is not lost

Restart the server process without changing **--nid** option and **--rsid** option.

You can use different IP address (--address option) from the crashed server on the substitute server. But be sure to take over all data including relay timestamp (*rts-*\* files) and update log (*ulog-*\* files).

### If data is lost

If data is lost, the server must be removed first。

    $ spreadctl node01 remove_node 1

Then add new node.

TODO: See Adding a server to existing replication-set


## Recovering configuration server

Since IP address of the configuration server can't be change, you must use same IP address of the crashed server on a substitute server. Or if exclusive IP alias is set for the address, set it to the substitute server.

Recovering operation of the configuration server is different depending on which data is lost or not.

### If data is not lost

Restart the spread-cs process.

### If data is lost

Configuration server stores cluster information (*membership* and *fault* files), and actually other nodes cache them.
So copy the cached information from another data server or gateway:

    [on node01]$ mkdir /var/spread/cs
    [on node01]$ scp node03:/var/spread/node03/membership node03:/var/spread/node03/fault /var/spread/cs/

Then restart the server process.


## Recovering gateway

Just restart it, since gateway is a *stateless* server.

