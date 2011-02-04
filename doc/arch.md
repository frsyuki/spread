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
Metadata servers store "which replication-set stores the data", and data servers store the data.

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
  2. GW (or DS) selects a replication-set that stores the data and insert its ID to MDS (metadata server). Weighted round-robin algorithm is used to select the replication-set.
  3. GW (or DS) sends add request to a DS in the replication-set.
  4. Other DSs in the replication-set replicate the stored data.


### Geting data

Metadata servers know which replication-set stores the data. So gateway (or data server) sends query to metadata server first, and then get data from the data server.

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
  2. GW (or DS) sends search query to MDS. MDS returns ID of replication-set that has the requested data if it's found.
  3. GW (or DS) selects a DS from the replication-set, and sends get request to the DS. The DS is selected using location-aware algorithm (TODO: See HowTo Geo-redundancy).


### Updating and geting attributes

Attributes are stored on metadata servers.

                        App     App     App
           (2)       (1) |       |       |
            ----------- GW      GW      GW
           /
    +-------------+
    |             |
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Application sends update or get request to a GW or DS. Any of GW or DS can respond to the requests.
  2. GW (or DS) sends a query to MDS.


## Controling and Monitoring

All data servers are registered on configuration server. Controling and monitoring tools deal with all data servers all together by changing settings on configuration server or taking server list from the configuration server.

                     (1)      (2)
      Administrator --> Tools --> CS
                         / \
    +-------------+     |   -------------  (3)
    |             |     |       |        \
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Administrator (you) runs a control tool with some arguments.
  2. The control tool takes cluster information from CS (configuration server).
  3. The control tool takes status or statistics from DSs and show them.

Next step: [Operations](operation.md)

