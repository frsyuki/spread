SpreadOSD
=========
A scalable distributed storage system.


## Overview

SpreadOSD is a distributed key-value storage system that can store large data like photos, musics, movies, etc.


## Architecture

SpreadOSD consists of 4 kind of servers:

  - **DS (data server)** stores and replicates contents on the disk.
  - **MDS (metadata server)** stores metadata of the contents. It includes the information that shows which DS stores the content. [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) is used for MDS.
  - **GW (gateway)** receives requests from applications and relays it to appropriate DS.
  - **CS (config server)** manages cluster information. It also watches status of DSs and detaches crashed DSs automatically.


Multiple DSs composes a group that each member stores same data. The group is called as **replication-set**.



                        App     App     App
                         |       |       |  MessagePack-RPC protocol
            ----------- GW      GW      GW
           /            /
    +-------------+    |  GW relays requests from apps to DSs
    | TokyoTyrant |    |
    |      |      |  +----+   +----+   +----+
    | TokyoTyrant |  | DS |   | DS |   | DS |
    |      |      |  |    |   |    |   |    | Multiple DSs a composes replication-set
    | TokyoTyrant |  | DS |   | DS |   | DS | DSs in a replication-set stores same data
    +-------------+  |    |   |    |   |    |
     MDSs store      | DS |   | DS |   | DS |
     metadata        +----+   +----+   +----+
                         \       |       /
                          -----  |  ----- CS manages cluster configuration
                               \ | /
                                CS

## Installation

Following libraries are required to run SpreadOSD:

  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) >= 1.1.40
  - [ruby](http://www.ruby-lang.org/) >= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) >= 0.4.3
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) >= 1.13

Configure and install in the usual way:

    $ ./bootstrap  # if needed
    $ ./configure
    $ make
    $ sudo make install

Or you can install using rake and gem.

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

Following commands will be installed:

  - spreadctl: Management tool
  - spreadcli: Command line client
  - spread-cs: CS server program
  - spread-ds: DS server program
  - spread-gw: GW server program


## Tutorial

Following example runs SpreadOSD on 6-node cluster:

    # Runs a dual-master Tokyo Tyrant servers.
    [on node01]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 1 \
                          -mhost node02 -rts /var/spread/sid1.rts
    [on node02]$ ttserver /var/spread/mds.tct -ulog /var/spread/ulog -sid 2 \
                          -mhost node01 -rts /var/spread/sid2.rts
    
    # Runs a CS.
    [on node01]$ spread-cs --mds node01,node02 -s /var/spread
    
    # Runs DSs for repliset-set 0.
    [on node03]$ spread-ds --cs node03 --address node03 --nid 0 --rsid 0 \
                 --name mynode03 --storage /var/spread
    [on node04]$ spread-ds --cs node04 --address node04 --nid 1 --rsid 0 \
                 --name mynode04 --storage /var/spread
    
    # Runs DSs for repliset-set 1.
    [on node05]$ spread-ds --cs node05 --address node05 --nid 2 --rsid 1 \
                 --name mynode05 --storage /var/spread
    [on node06]$ spread-ds --cs node06 --address node06 --nid 3 --rsid 1 \
                 --name mynode06 --storage /var/spread
    
    # Runs a GW on the application server.
    [on client]$ spread-gw --mds node01 --port 18800

Confirm status of the cluster using *spreadctl* command:

    $ spreadctl node01 nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

Now the cluster is active. Try to set and get using *spreadcli* command:

    # GW is running on localhost
    [on client]$ spreadcli 127.0.0.1 set "key1" '{"type":"png","data":"..."}'
    true
    
    [on client]$ spreadcli 127.0.0.1 get "key1"
    {"type":"png","data":"..."}


### Run on single host

You can test SpreadOSD on single host as follows:

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



## Cluster management

### Adding new DSs

First, confirm the status of the cluster using *spreadctl* command.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

Next, run new servers.

At last, the status will change:

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active
      4        mynode07      192.168.0.15:18900         2     active
      5        mynode08      192.168.0.16:18900         2     active

You may want to decrease the weight of the old replication sets.


### Changing weight of load balancing

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


### Recovering crashed DSs

If a DS is crashed, it status will be "FAULT". Confirm it using *spreadctl* first.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

If the data is not lost, just restart the fault server.
Otherwise, run a new server using the same --nid and --rsid option with the crashed server.

Then confirm that the status is went back to "active".

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode07      192.168.0.17:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active


### Detaching crashed DSs

If a DS is crashed, it status will be "FAULT". Confirm it using *spreadctl* first.

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      1        mynode04      192.168.0.14:18900         0     FAULT
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active

If you want to detach the instead of recovering, run following command:

    $ spreadctl csaddr remove_node 2

Then confirm the status:

    $ spreadctl csaddr nodes
    nid            name                 address   replset      state
      0        mynode03      192.168.0.13:18900         0     active
      2        mynode05      192.168.0.15:18900         1     active
      3        mynode06      192.168.0.16:18900         1     active


### Recovering crashed CS

Just restart it.

Note that CS stores status of the cluster to "$storage_path/membership" and "$storage_path/fault" file.

If membership file is lost, DSs whose status is "FAULT" will become detached.
If fault file is lost, DSs whose status is "FAULT" will become "active", and go back to "FAULT" after timeout time elapsed.

If you are going to recover these DSs, recover DSs before restarting CS.


### Recovering crashed GW

GW is a *stateless* server, so just restart it.


## Protocol

SpreadOSD uses [MessagePack-RPC](http://msgpack.org/) as a client protocol.

Client applications can use following commands:

### get(key:Raw) -> map:Map<Raw,Raw>
Gets a map from the storage.

Returns the found map if it success. Otherwise, it returns an empty map.


### set(key:Raw, map:Map<Raw,Raw>) -> success:Boolean
Sets a map to the storage. A column named "data" in the *map* will be stored on DS. Other columns are stored on MDS.

Returns true if it succeeded. Otherwise, it returns false.


### remove(key:Raw) -> success:Boolean
Removes a map from the storage. A column named "data" in the *map* will be stored on DS. Other columns are stored on MDS.

Returns true if it succeeded. Otherwise, it returns false.


### get_direct(key:Raw, rsid:Integer) -> data:Raw or nil
Gets a data from the storage. This function does not access to the MDS.

Returns the found data if it success. Otherwise, it returns nil.


### set_direct(key:Raw, data:Raw, rsid:Integer) -> success:Boolean
Sets a data to the storage. This function does not access to the MDS.

Returns true if it succeeded. Otherwise, it returns false.


### remove_direct(key:Raw, rsid:Integer) -> succeeded:Boolean
Removes a data to the storage. This function does not access to the MDS.

Returns true if it succeeded. Otherwise, it returns false.


## Reference

### spreadctl

    Usage: spreadctl <cs address[:port]> <command> [options]
    command:
       nodes                        show list of nodes
       replset                      show list of replication sets
       stat                         show status of nodes
       items                        show stored number of items
       remove_node <nid>            remove a node from the cluster
       set_weight <rsid> <weight>   set distribution weight

### spreadcli

    Usage: spreadcli <cs address[:port]> <command> [options]
    command:
       set <key> <json>                 set a map
       get <key>                        get the map and show json
       remove <key>                     remove the map
       get_data <key>                   get the map and show map["data"]
       set_data <key> <data>            set a map {"data":data}
       get_direct <rsid> <key>          get the data from the replication set directly
       set_direct <rsid> <key> <data>   set the data to the replication set directly
       remove_direct <rsid> <key>       remove the data from the replication set directly

### spread-cs

    Usage: spread-cs [options]
        -p, --port PORT                  listen port
        -s, --storage PATH               path to base directory
        -f, --fault_path PATH            path to fault status file
        -b, --membership PATH            path to membership status file
        -t, --mds ADDRESS                address of metadata server


### spread-ds

    Usage: spread-ds [options]
        -i, --nid ID                     unieque node id
        -n, --name NAME                  node name
        -a, --address ADDRESS            listen address
        -g, --rsid IDs                   replication set IDs
        -s, --storage PATH               path to storage directory
        -u, --ulog PATH                  path to update log directory
        -r, --rlog PATH                  path to relay log directory
        -m, --cs ADDRESS                 address of config server
        -f, --fault_path PATH            path to fault status file
        -b, --membership PATH            path to membership status file

### spread-gw

    Usage: spread-gw [options]
        -p, --port PORT                  listen port
        -m, --cs ADDRESS                 address of config server
        -s, --storage PATH               path to base directory
        -f, --fault_path PATH            path to fault status file
        -b, --membership PATH            path to membership status file



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

