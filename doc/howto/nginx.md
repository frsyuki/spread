Direct data transfer using Nginx's X-Accel-Redirect - SpreadOSD HowTo
=====================================================================

## Readers of this HowTo

Photo storage system of web services is one of the most suitable usages of SpreadOSD. In these web sites, you probably use HTTP load balancers in front of the application servers.
If you are using [Nginx](http://wiki.nginx.org/Main) as the HTTP load balancer, you can reduce CPU load and network traffic of the application servers using nginx's "X-Accel-Redirect" feature.

It assumes following web backend system in this document:

                               Internet
                                  |
                             load balancer
                              /
                       reverse proxy
                         | (1)
                         | (5)
                        App
           (3)       (2) |
            ----------- GW
           /            /
    +-------------+    |
    |             |    | (4)
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Reverse proxy relays requests to the application server.
  2. Application sends a request to gateway (GW) to get data.
  3. GW sends a query to metadata server (MDS).
  4. GW gets large data from appropriate DS.
  5. Application returns large data to reverse proxy.


You can reduce CPU load and network traffic by setting up following architecture described in this document:


                               Internet
                                  |
                             load balancer
                              /
                       reverse proxy (nginx)
                       (4) / |
                      (1) /  |
                        App  |
           (3)       (2) |   |
            ----------- GW   | (5)
           /                /
    +-------------+      ---
    |             |     /
    |             |  +----+   +----+   +----+
    |     MDS     |  | DS |   | DS |   | DS |
    |             |  |    |   |    |   |    |
    |             |  | DS |   | DS |   | DS |
    +-------------+  |    |   |    |   |    |
                     | DS |   | DS |   | DS |
                     +----+   +----+   +----+

  1. Reverse proxy (nginx) relays requests to the application server.
  2. Application sends a request to gateway (GW) to get actual URL of the data on a DS.
  3. GW sends a query to metadata server (MDS).
  4. Application returns the URL to nginx with X-Accel-Redirect header.
  5. Nginx gets large data from the DS.


## Nginx setting

    location / {
      proxy_pass  http://real.server.host;
    
      # the application should return
      #      X-Accel-Redirect: /reproxy
      #      X-Reproxy-URL: http://url/got/from/spread-gw
    }
    
    location = /reproxy {
      # make this location internal-use only
      internal;
    
      # set $reproxy variable to the value of X-Reproxy-URL header
      set $reproxy $upstream_http_x_reproxy_url;

      # pass to the URL
      proxy_pass $reproxy;
    }

TODO


## Application code

TODO


### Adding headers

TODO

Content-Types


## Accelerating DS performance by offloading GET requests to Nginx

TODO


## References

  - [Re: Can I use lighttpd/nginx for webdav but have updated disk usage statistics for mogile?](http://www.mail-archive.com/mogilefs@lists.danga.com/msg00366.html)

