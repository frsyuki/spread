Plug-in reference - SpreadOSD
============================

## Storage plug-in

You can choose a storage implementation by specifing scheme to the *--store* option on the data server (DS). The default is Directory Storage.


### Directory Storage (dir:)

This uses local directory for the storage.

Scheme is **dir:&lt;path&gt;**

## MDS plug-in

You can choose a implementation of metadata server (MDS) by specifing scheme to the *--mds* option on config server (CS). The default is Tokyo Tyrant.

### Tokyo Tyrant (tt:)

This uses [Tokyo Tyrant](http://fallabs.com/tokyotyrant/)'s table database for the MDS.
It supports versioning.

Scheme is **tt:&lt;servers&gt;[;&lt;weights&gt;]**


### Memcache (mc:)

This uses memcached protocol for the MDS.
It does NOT support versioning.

This plug-in is intended to use persistent storage system that supports memcached protocol like [Kumofs](http://kumofs.sourceforge.net/), [Flare](http://labs.gree.jp/Top/OpenSource/Flare-en.html), [Membase](http://www.membase.org/), etc.
Don't use memcached.

Scheme is **mc:&lt;servers&gt;[;&lt;weights&gt;]**


## MDS cache plug-in

You can enable metadata cache by adding *--mds-cache* option on gateway (or data server).

### Memcached (mc:)

This uses [memcached](http://memcached.org/) for the the MDS cache.

Scheme is **mc:&lt;servers&gt;[;&lt;expire&gt;]**


### Local memory (lcoal:)

This uses local memory for the MDS cache.
Because cached data are not shared, updating APIs operations may occur consistency problem.

Schem is **local:&lt;size&gt;**


