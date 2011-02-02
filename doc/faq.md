FAQ - SpreadOSD
===============

## FAQ

### DS or GW says "sytem time must be adjusted"

This message is shown when system time of the DS or GW is too different from the system time of CS. You should use ntpd or ntpdate command to adjust it.

GW (or DS) uses system time to set creation time when adding (and removing) a object. It is used to get old version of objects. If the system time is not adjusted correctly, You can't get exact snapshot by specifying object's version in time using getv on RPC or vtime= parameter on HTTP.


