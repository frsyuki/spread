FAQ - SpreadOSD
===============

## FAQ

### DS or GW says "sytem time must be adjusted"

This message is shown when system time of the DS or GW is too different from the system time of CS. You should use ntpd or ntpdate command to adjust it.

GW (or DS) uses system time to set creation time when adding (and removing) a object. It is used to get old version of objects. If the system time is not adjusted correctly, You can't get exact snapshot by specifying object's version in time using getv on RPC or vtime= parameter on HTTP.


### How to know where the data was stored?

Use **spreadctl** **locate** command as follows:

    $ spreadctl cs.node locate mykey
    vtime=[2011-02-04 18:12:15 +0900]  vname=nil    rsid=1:
       > node05          nid=2        192.168.0.15:18900      subnet-192.168.000
       > node06          nid=3        192.168.0.16:18900      subnet-192.168.000

