SpreadOSD
=========
A scalable distributed storage system.


## Overview

SpreadOSD is a distributed storage system that can store large data link photos, music movies, etc.

You can increase storage capacity dynamically as adding servers.
Replication is supported, and failover is done within a very short downtime.


## Architecture

SpreadOSD consists of 4 kind of servers:

  - **DS (data server)** stores and replicates contents on the disk.
  - **MDS (metadata server)** stores metadata of the contents. It includes the information that shows which DS stores the content. [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) is used for MDS.
  - **GW (gateway)** receives requests from applications and relays it to appropriate DS. You can use DS as a GW because DS has features of GW.
  - **CS (config server)** manages cluster configuration. It also watches status of DSs and detaches crashed DSs automatically.

Multiple DSs composes a group that each member stores same data. The group is called **replication-set**.


                        App     App     App
                         |       |       |  MessagePack-RPC protocol
            ----------- GW      GW      GW or DS
           /            /
    +-------------+    |  GW relays requests from apps to DSs
    | TokyoTyrant |    |
    |      |      |  +----+   +----+   +----+
    | TokyoTyrant |  | DS |   | DS |   | DS |
    |      |      |  |    |   |    |   |    | Multiple DSs composes a replication-set
    | TokyoTyrant |  | DS |   | DS |   | DS | DSs in a replication-set store same data
    +-------------+  |    |   |    |   |    |
     MDSs store      | DS |   | DS |   | DS | ... You can add replication-sets at any time
     metadata        +----+   +----+   +----+
                         \       |       /
                          -----  |  ----- CS manages cluster configuration
                               \ | /
                                CS


## Installation

Following softwares are required to run SpreadOSD:

  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) &gt;= 1.1.40
  - [ruby](http://www.ruby-lang.org/) &gt;= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) &gt;= 0.4.3
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) &gt;= 1.13
  - [rack gem](http://rubygems.org/gems/rack) &gt;= 1.2.1

There are 2 way to install SpreadOSD.

One way is to use ./configure && make install:

    $ ./bootstrap  # if needed
    $ ./configure
    $ make
    $ sudo make install

The other way is to use rake and gem:

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

If your site uses Ruby widely, the latter way will be good choice to manage multiple versions.

Following commands will be installed:

  - spreadctl: Management tool
  - spreadcli: Command line client
  - spread-cs: CS server program
  - spread-ds: DS server program
  - spread-gw: GW server program


### Full installation guide

In this guide, you will install all systems on /opt/local/spread directory.

First, install folowing packages using the package management system.

  - gcc-g++ &gt;= 4.1
  - openssl-devel (or libssl-dev) to build ruby
  - zlib-devel (or zlib1g-dev) to build ruby
  - readline-devel (or libreadline6-dev) to build ruby

Following guide installs SpreadOSD on /opt/local/spread.

    # Installs Tokyo Tyrant into /opt/local/spread
    $ wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz
    $ tar zxvf tokyotyrant-1.1.41.tar.gz
    $ cd tokyotyrant-1.1.41
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
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


## Tutorial

Following example runs SpreadOSD on 6-node cluster:

    # Runs two Tokyo Tyrant servers as dual-master.
    [on node01]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 1 \
                          -mhost node02 -rts /var/spread/sid1.rts
    [on node02]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 2 \
                          -mhost node01 -rts /var/spread/sid2.rts
    
    # Runs a CS.
    [on node01]$ spread-cs --mds node01 -s /var/spread
    
    # Runs DSs for repliset-set 0.
    [on node03]$ spread-ds --cs node03 --address node03 --nid 0 --rsid 0 \
                           --name mynode03 --store /var/spread
    [on node04]$ spread-ds --cs node04 --address node04 --nid 1 --rsid 0 \
                           --name mynode04 --store /var/spread
    
    # Runs DSs for repliset-set 1.
    [on node05]$ spread-ds --cs node05 --address node05 --nid 2 --rsid 1 \
                           --name mynode05 --store /var/spread
    [on node06]$ spread-ds --cs node06 --address node06 --nid 3 --rsid 1 \
                           --name mynode06 --store /var/spread
    
    # Runs a GW on the application server.
    [on client]$ spread-gw --cs node01 --port 18800 --http 18080

Confirm status of the cluster using *spreadctl* command.

    $ spreadctl node01 nodes
    nid            name                 address                location    rsid      state
      0        mynode03      192.168.0.13:18900      subnet-127.000.000       0     active
      1        mynode04      192.168.0.14:18900      subnet-127.000.000       0     active
      2        mynode05      192.168.0.15:18900      subnet-127.000.000       1     active
      3        mynode06      192.168.0.16:18900      subnet-127.000.000       1     active


Now the cluster is active. Try to set and get using *spreadcli* command.

    # GW is running on localhost
    [on client]$ spreadcli 127.0.0.1 set "key1" 'val1' '{"type":"png"}'
    
    [on client]$ spreadcli 127.0.0.1 get "key1"
    {"type":"png"}
    val1


### Run on single host

You can test SpreadOSD on single host as follows:

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


## Cluster management

### Adding new DSs

First, confirm the status of the cluster using *spreadctl* command.

    $ spreadctl csaddr nodes
    nid            name                 address                location    rsid      state
      0        mynode03      192.168.0.13:18900      subnet-127.000.000       0     active
      1        mynode04      192.168.0.14:18900      subnet-127.000.000       0     active
      2        mynode05      192.168.0.15:18900      subnet-127.000.000       1     active
      3        mynode06      192.168.0.16:18900      subnet-127.000.000       1     active

Next, run new servers.

Then confirm the status.

    nid            name                 address                location    rsid      state
      0        mynode03      192.168.0.13:18900      subnet-127.000.000       0     active
      1        mynode04      192.168.0.14:18900      subnet-127.000.000       0     active
      2        mynode05      192.168.0.15:18900      subnet-127.000.000       1     active
      3        mynode06      192.168.0.16:18900      subnet-127.000.000       1     active
      2        mynode07      192.168.0.17:18900      subnet-127.000.000       2     active
      3        mynode08      192.168.0.18:18900      subnet-127.000.000       2     active

You may want to decrease the *weight* of the old replication sets.


### Changing weight of load balancing

You can set a **weight** parameter for replication-sets. It affects to decieds which replication-set is selected to store a new data. The default weight is 10.

A replication-set is selected at the probability of **weight / (sum of all weights)**.

If the weight is 0, new data will never be stored on the replication-set.

You can change the weight using *spreadctl* command.

    $ spreadctl csaddr weight
    rsid   weight       nids   names
       0       10        0,1   mynode03,mynode04
       1       10        2,3   mynode05,mynode06
       2       10        4,5   mynode07,mynode08

    # Set 5 to weight of replication set 0
    $ spreadctl csaddr set_weight 0 5

    # Set 5 to weight of replication set 1
    $ spreadctl csaddr set_weight 1 5

    $ spreadctl csaddr weight
    rsid   weight       nids   names
       0        5        0,1   mynode03,mynode04
       1        5        2,3   mynode05,mynode06
       2       10        4,5   mynode07,mynode08


### Recovering crashed DSs

If a DS is crashed, its status will be **FAULT**. Confirm it using *spreadctl* first.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

#### If data is not lost

Restart the fault server. Use same **--nid** option and same **--rsid** option.

Confirm that the status is went back to **active**.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

#### If data is lost

First, detach the crashed server as follows:

    $ spreadctl csaddr remove_node 2

Second, copy whole data from other DS in the same replication-set. For example, run rsync as follows:

    # Copy relay time stamps from node03 first
    [on node07]$ scp node03:/var/spread/rts-* /var/spread/

    # Copy data from node03 excluding update logs and relay time stamps
    # rsync option:
    #   -a  Archive mode
    #   -v  Verbose mode
    #   -e  Uses ssh with arcfour128 cipher algorithm.
    #       Note that arcfour128 is fast but weak algorithm.
    #       Use "blowfish" if the network is insecure.
    #   --bwlimit limits bandwidth in KB/s
    [on node07]$ rsync -av -e 'ssh -c arcfour128' --exclude "ulog-*" --excluding "rts-*" \
                       --bwlimit 32768 node03:/var/spread/ /var/spread/
    
    # Ensure update logs are removed
    [on node07]$ rm -f /var/spread/ulog-*

You do not have to stop the source node (node03, in this example).

Third, run a new server using the same *--nid* option with the crashed server. New unique ID must be assigned for --nid option.

Then confirm that the status of the cluster.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active
      4        mynode07      192.168.0.17:18900         0     active


### Detaching crashed DSs

If a DS is crashed, its status will be **FAULT**. Confirm it using *spreadctl* first.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

If you want to detach the instead of recovering, run following command:

    $ spreadctl csaddr remove_node 2

Then confirm the status.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active


### Recovering crashed CS

Just restart it.

Note that CS stores status of the cluster to "$store\_path/membership" and "$store\_path/fault" file.

If membership file is lost, DSs whose status is **FAULT** will become detached.
If fault file is lost, DSs whose status is **FAULT** will become **active**, and go back to **FAULT** after timeout time elapsed.

If you are going to recover these DSs, recover DSs before restarting CS.


### Recovering fault GW

GW is a *stateless* server, so just restart it.



## Application interface

SpreadOSD uses [MessagePack-RPC](http://msgpack.org/) and HTTP as a client protocol.

### MessagePack-RPC


#### get(key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]
Gets data and attributes from the storage.

Returns the found data and attributes if it success. Otherwise, it returns [nil, nil].


#### get\_data(key:Raw) -&gt; data:Raw
Gets data from the storage.

Returns the found data if it success. Otherwise, it returns nil.


#### get\_attrs(key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;
Gets attributes from the storage.

Returns the found attributes if it success. Otherwise, it returns nil.


#### gets(sid:Integer, key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]
Gets data and attributes from the storage using the snapshot.

Returns the found data and attributes if it success. Otherwise, it returns [nil, nil].


#### gets\_data(sid:Integer, key:Raw) -&gt; data:Raw
Gets data from the storage using the snapshot.

Returns the found data if it success. Otherwise, it returns nil.


#### gets\_attrs(sid:Integer, key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;
Gets attributes from the storage using the snapshot.

Returns the found attributes if it success. Otherwise, it returns nil.


#### read(key:Raw, offset:Integer, size:Integer) -&gt; data:Raw
Reads part of data from the storage.

Returns the found data if it success. Otherwise, it returns nil.


#### reads(sid:Integer, key:Raw, offset:Integer, size:Integer) -&gt; data:Raw
Reads part of data from the storage using the snapshot.

Returns the found data if it success. Otherwise, it returns nil.


#### getd\_data(objectKey:Object) -&gt; data:Raw
Gets data from DS directly.

Returns the found data if it success. Otherwise, it returns nil.


#### readd(objectKey:Object, offset:Integer, size:Integer) -&gt; data:Raw
Reads part of data from DS directly.

Returns the found data if it success. Otherwise, it returns nil.


#### set(key:Raw, data:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object
Sets data and attributes to the storage.
The data is stored on DS, and the attributes are stored on MDS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### set\_data(key:Raw, data:Raw) -&gt; objectKey:Object
Sets data to the storage. The data is stored on DS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### set\_attrs(key:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object
Sets attributes to the storage. The attributes is stored on MDS.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### write(key:Raw, offset:Integer, data:Raw) -&gt; objectKey:Object
Writes part of data to the storage.

Returns object key of the stored object if it succeeded. Otherwise, it returns false.


#### remove(key:Raw)
Removes data and attributes from the storage.

Returns true if the object is removed. Otherwise, it returns false.


#### select(cols, conds, order, order\_col, limit, skip) -&gt; arrayOfAttributes:Array&lt;Map&lt;Raw,Raw&gt;&gt;

    cols:Array<String> or nil
    conds:Array<Condition>
    order:Integer or nil
    order_col:Raw or nil
    limit:Integer or nil
    skip:Integer or nil


#### selects(sid, cols, conds, order, order\_col, limit, skip) -&gt; arrayOfAttributes:Array&lt;Map&lt;Raw,Raw&gt;&gt;



### HTTP

TODO



## Reference

### spreadctl

**spreadctl** is a control command of the cluster.

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       nodes                        show list of nodes
       replset                      show list of replication sets
       stat                         show statistics of nodes
       items                        show stored number of items
       remove_node <nid>            remove a node from the cluster
       set_weight <rsid> <weight>   set distribution weight
       snapshot                     show snapshot list
       add_snapshot <name>          add a snapshot
       version                      show software version of nodes


### spreadcli

**spreadcli** is a command line client program.

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



## Modifing source code

SpreadOSD is licensed as an open source software. You can modify its source code.

### Source tree

    lib/spread-osd
    |
    +-- lib/                    Fundamental libraries
    |   |
    |   +-- ebus.rb             EventBus
    |   +-- cclog.rb            A logging library
    |   +-- vbcode.rb           Variable byte code
    |
    +-- logic/
    |   |
    |   +-- node.rb             Definition of the Node class
    |   +-- tsv_data.rb         Base class to use tab separated value
    |   +-- fault_detector.rb   Fault detector
    |   +-- membership.rb       Node list and replication-set list
    |   +-- weight.rb           Load balancing feature
    |   +-- snapshot.rb         Snapshot list
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
    |   +-- ctl.rb              Control tool
    |   +-- cs.rb               CS main
    |   +-- ds.rb               DS main
    |   +-- gw.rb               GW main
    |   +-- cli.rb              Command line client program
    |
    +-- default.rb              Some constants like default port number
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

