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

Replication strategy of SpreadOSD is combination of multi-master replication. When a master server is crashed, a slave server fails-over automatically at minimal downtime.

SpreadOSD also supports inter-datacenter replication (aka. geo-redundancy). Each data is stored over multiple datacenters and you can prepare for disasters.

Snapshot feature is also supported.


### Maintainability




You can increase storage capacity dynamically as adding servers.
Replication is supported, and failover is done within a very short downtime.



