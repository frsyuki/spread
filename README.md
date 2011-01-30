SpreadOSD
=========
A scalable distributed storage system.


## Overview

SpreadOSD is a distributed storage system that can store large data like photos, music or movies.
SpreadOSD cluster provides high **Scalability**, **Availability** and **Maintainability** for storage system.


### Scalability

Storage capacity and I/O throughput grow as you add servers.
Since change of cluster configuration is hidden from applications, you can scales-out without stopping or reconfiguring the application.


### Availability

SpreadOSD supports replication. Data won't be lost even if some servers crashed. Also I/O requests from applications will be proceeded normally.

Replication strategy of SpreadOSD is combination of multi-master replication. When a master server is crashed, another master server fails-over automatically at minimal downtime.

SpreadOSD also supports inter-datacenter replication (aka. geo-redundancy). Each data is stored over multiple datacenters and you can prepare for disasters.


### Maintainability

SpreadOSD provides some management tools to control all data servers all together. And you can visualize load of servers with monitoring tools.

It means that management cost doesn't grow even if scale of the cluster grows.


### Data model

SpreadOSD stores set of *objects* identified by a key. Each object has both data (an sequence of bytes) and attributes (an associative array).

        key             data                  attributes
    +----------+-------------------+---------------------------------+
    | "image1" |  "HTJ P N G" ...  |  { type:png, date:2011-07-29 }  |
    +----------+-------------------+---------------------------------+
    |  key     |  bytes .........  |  { key:value, key:value, ... }  |
    +----------+-------------------+---------------------------------+
    |  key     |  bytes .........  |  { key:value, key:value, ... }  |
    +----------+-------------------+---------------------------------+
    ...

And each object can have multiple versions. You can get back old version of the object unless you surely delete it.


## Learm more

  - TODO: See Architecture
  - TODO: See Install
  - TODO: See API Reference


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



Architecture - SpreadOSD
========================

SpreadOSD is a distributed storage system that provides high scalability and availability.
It describes the architecture of the SpreadOSD in this document.

## Kind of servers

SpreadOSD consists of 4 kind of servers:

  - **DS (data server)** stores and replicates contents on the disk.
  - **MDS (metadata server)** stores metadata of the contents. It includes the information that shows which DS stores the content. [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) is used for MDS.
  - **GW (gateway)** receives requests from applications and relays it to appropriate DS. You can use DS as a GW because DS has features of GW.
  - **CS (config server)** manages cluster configuration. It also watches status of DSs and detaches crashed DSs automatically.

Multiple DSs composes a group whose member stores same data. The group is called **replication-set**.


                        App     App     App
                         |       |       |  HTTP or MessagePack-RPC protocol
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


## Operations

### Adding data

Gateway (or aata server) relays requests from applications to metadata servers and data servers.
Metadata servers store "which replication-set stores the actual data", and data servers store the actual data.

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /            /
    +-------------+    |
    |             |    | (3)
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | | (4)  |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | | (4)  |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Application sends add request to a GW (gateway) or DS (data server). Any of GW or DS can respond to the requests.
  2. GW or DS selects a replication-set that stores the data and insert its ID to MDS (metadata server). The replication-set is selected using weighted round-robin algorithm.
  3. GW or DS sends add request to a DS in the replication-set.
  4. Other DSs in the replication-set replicate the stored data.


### Geting data

Metadata servers know which replication-set stores the actual data. So gateway (or data server) sends query to metadata server first, and then get data from the data server.

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /            /
    +-------------+    |
    |             |    | (3)
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Application sends get request to a GW or DS. Any of GW or DS can respond to the requests.
  2. GW or DS sends search query to MDS. MDS returns ID of replication-set that has the requested data if it's found.
  3. GW or DS sends get request to one of DS in the replication-set. The DS is selected using location-aware algorithm (TODO: See HowTo Geo-redundancy).


### Updating and geting metadata

Metadata is stored on metadata servers.

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /
    +-------------+
    |             |
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | |  |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | |  |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Application sends update or get request to a GW or DS. Any of GW or DS can respond to the requests.
  2. GW or DS sends a query to MDS.


## Control and Monitoring

All data servers are registered on configuration server. Control and monitoring tools helps you to gather information from the data servers by taking server list from the configuration server.

                     (1)      (2)
       Administrator --> Tool --> CS
                         / \
    +-------------+     |   -------------  (3)
    |             |     |       |        \
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  | |  |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  | |  |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Administrator (you) runs a control tool with some arguments.
  2. The control tool takes cluster information from CS (configuration server).
  3. The control tool takes status or statistics from DSs and show them.


Install - SpreadOSD
===================

SpreadOSD is a distributed storage system implemed in Ruby.
You can install using *make install* or using RubyGems.


## Requirements

Following softwares are required to run SpreadOSD:

  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) &gt;= 1.1.40
  - [ruby](http://www.ruby-lang.org/) &gt;= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) &gt;= 0.4.3
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) &gt;= 1.13
  - [rack gem](http://rubygems.org/gems/rack) &gt;= 1.2.1


## Choice 1: Install using RubyGems

One way is to use rake and gem:

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

If your site uses Ruby widely, RubyGems will be good choice to manage version of softwares.

## Choice 2: Install using make-install

The other way is to use ./configure && make install:

    $ ./bootstrap  # if needed
    $ ./configure RUBY=/usr/local/bin/ruby
    $ make
    $ sudo make install

Following commands will be installed:

  - spreadctl: Management tool
  - spreadcli: Command line client
  - spread-cs: CS server program
  - spread-ds: DS server program
  - spread-gw: GW server program

## Compiling Ruby 1.9 for exclusive use

In this guide, you will install all systems on /opt/local/spread directory.

First, install folowing packages using the package management system.

  - gcc-g++ &gt;= 4.1
  - openssl-devel (or libssl-dev) to build ruby
  - zlib-devel (or zlib1g-dev) to build ruby
  - readline-devel (or libreadline6-dev) to build ruby

Following guide installs SpreadOSD on /opt/local/spread.

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
    
    # Installs Tokyo Tyrant into /opt/local/spread
    $ wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz
    $ tar zxvf tokyotyrant-1.1.41.tar.gz
    $ cd tokyotyrant-1.1.41
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install

TODO: Tokyo Cabinet
TODO: Install Tokyo Tyrant using apt or yum


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
    #      --nid (unique node id)
    #      --rsid (replication set id to join)
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

Now you can use HTTP client to use SpreadOSD.

    [localhost]$ curl -X POST -d 'data=value1&attrs={"test":"attr"}' http://localhost:18080/data/key1
    
    [localhost]$ curl -X GET http://localhost:18080/data/key1
    value1
    
    [localhost]$ curl -X GET http://localhost:18080/attrs/key1
    {"test":"attr"}
    
    [localhost]$ curl -X GET -d 'format=tsv' http://localhost:18080/attrs/key1
    test	attr

(TODO: See API Reference)


## Running on cluster

It runs runs 6-node cluster in following tutorial:


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
    
    # node03: runs DS for repliset-set 0.
    [on node03]$ mkdir /var/spread/node03
    [on node03]$ spread-ds --cs node01 --address node03 --nid 0 --rsid 0 \
                           --name node03 -s /var/spread/node03
    
    # node04: runs DS for repliset-set 0.
    [on node04]$ mkdir /var/spread/node04
    [on node04]$ spread-ds --cs node01 --address node04 --nid 1 --rsid 0 \
                           --name node04 -s /var/spread/node04
    
    # node05: runs DS for repliset-set 1.
    [on node05]$ mkdir /var/spread/node05
    [on node05]$ spread-ds --cs node01 --address node05 --nid 2 --rsid 1 \
                           --name node05 -s /var/spread/node05
    
    # node06: runs DS for repliset-set 1.
    [on node06]$ mkdir /var/spread/node06
    [on node06]$ spread-ds --cs node01 --address node06 --nid 3 --rsid 1 \
                           --name node06 -s /var/spread/node06
    
    # on application server: runs a GW.
    [on app-svr]$ spread-gw --cs node01 --port 18800 --http 18080

Confirm status of the cluster using *spreadctl* command.

    [localhost] $ spreadctl localhost nodes
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


Operaionts - SpreadOSD
======================

TODO



Fault management - SpreadOSD
============================

TODO



Commandline reference - SpreadOSD
=================================

TODO



API - SpreadOSD
================

## HTTP API

TODO

## MessagePack-RPC API

TODO



Debugging and Improvement - SpreadOSD
=====================================

TODO

## Source tree

    lib/spread-osd
    |
    +-- lib/                    Fundamental libraries
    |   |
    |   +-- ebus.rb             EventBus
    |   +-- cclog.rb            Logging library
    |   +-- vbcode.rb           Variable byte code
    |
    +-- logic/
    |   |
    |   +-- node.rb             Definition of the Node class
    |   +-- okey.rb             Definition of the ObjectKey class
    |   +-- tsv_data.rb         Base class to use tab separated values
    |   +-- fault_detector.rb   Fault detector
    |   +-- membership.rb       Node list and replication-set list
    |   +-- weight.rb           Load balancing feature
    |
    +-- service/
    |   |
    |   +-- base.rb
    |   +-- bus.rb
    |   |
    |   +-- process.rb
    |   |
    |   +-- heartbeat.rb
    |   +-- sync.rb
    |   +-- time_check.rb
    |   |
    |   +-- membership.rb
    |   +-- master_select.rb
    |   +-- balance.rb
    |   +-- weight.rb
    |   |
    |   +-- data_client.rb
    |   +-- data_server.rb
    |   +-- data_server_url.rb
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


