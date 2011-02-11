NginxのX-Accel-Redirectを使って直接データを転送する - SpreadOSD
================================================================

## このHowToの読者

SpreadOSDの用途の一つにWebサービスの画像ストレージシステムがあります。このようなWebサイトでは、アプリケーションサーバの全面にHTTPリバースプロキシを設置しているでしょう。
もしHTTPリバースプロキシとして[nginx](http://wiki.nginx.org/Main)を使っているなら、nginxの "X-Accel-Redirect" 機能を組み合わせる事で、アプリケーションサーバのCPU負荷とトラフィックを削減することができます。

このドキュメントでは、次のようなWebバックエンドシステムを想定しています：

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

  1. リバースプロキシがアプリケーションサーバに要求を中継します
  2. アプリケーションがGW（Gateway）にデータを取得する要求を送信します
  3. GWがMDS（Metadata Server）にクエリを発行します
  4. GWがデータを適切なDSから取得します
  5. アプリケーションがデータをリバースプロキシに返します

次のような構成をセットアップすることで、CPU負荷とトラフィックを削減できます：

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

  1. リバースプロキシ（nginx）がアプリケーションサーバに要求を中継します
  2. アプリケーションがGWに実際のデータが保存されているDSへのURLを要求します
  3. GWがMDSにクエリを送信します
  4. アプリケーションがX-Accel-Redirectヘッダと共に、nginxにURLを返します
  5. nginxがDSからデータを取得します


## nginxの設定

次の設定をnginx.confに追加します：

    # location setting for real application servers
    location / {
      proxy_pass  http://real.server.host;
    
      # the application should return:
      #      X-Accel-Redirect: /reproxy
      #      X-Reproxy-URL: http://host:port/url/got/from/spread-gw
      #      Content-Type: actual/content-type
    }
    
    location = /reproxy {
      # make this location internal-use only
      internal;
    
      # set $reproxy variable to the value of X-Reproxy-URL header
      set $reproxy $upstream_http_x_reproxy_url;

      # pass to the URL
      proxy_pass $reproxy;

      # inherits Content-Type header
      proxy_hide_header Content-Type
    }


## アプリケーション

アプリケーションは、"X-Accel-Redirect"、"X-Reproxy-URL"、そして"Content-Type"ヘッダを含んだ応答を返します。

"X-Accel-Redirect"ヘッダには、nginxの内部locationの名前を指定します。この例では、"X-Accel-Redirect: /reproxy"を指定します。

"X-Reproxy-URL"ヘッダには、GWから取得した実際のURLを指定します。

"Content-Type"ヘッダには、実際のデータのContent-Typeを指定します。

    require 'sinatra'
    require 'net/http'
    
    get '/get_my_image' do
      # Gets actual URL of the data from spread-gw
      url = nil
      Net::HTTP.start("gateway01", 8088) do |http|
        res = http.get("/api/uri?key=my_image")
        url = res.body
      end
      
      # Sets response headers
      headers "X-Accel-Redirect" => "/reproxy"
      headers "X-Reproxy-URL" => url
      headers "Content-Type" => "image/png"
      
      # Returns empty body
      return ""
    end


## DSの設定

すべてのDSに*--http PORT*引数を指定して、HTTPインタフェースを有効にしておく必要があります。

    [on node04]$ spread-ds --cs cs.node --address node04 --nid N --rsid R --name N \
                           -s /var/spread/node04 \
                           --http 19800

あるいは、*--http-redirect-port PORT*引数を指定して、別のHTTPサーバを使ってデータを転送します。


### GETリクエストをオフロードしてDSの性能を向上させる

DSはRubyで書かれており、動作は低速です。別のHTTPサーバ（nginxやlighttpd、thttpdなど）を使ってGETリクエストを処理することで、性能を向上させることができます。

#### thttpdを使う

    [on node04]$ thttpd -p 19800 -d /var/spread/node04/data

#### nginxを使う

    server {
      listen 19800;
      server_name localhost;
      sendfile on;
      location / {
        root /var/spread/node04/data;
      }
    }

#### DSの設定

<!--
TODO
-->

    [on node04]$ spread-ds --cs cs.node --address node04 --nid N --rsid R --name N \
                           -s /var/spread/node04 \
                           --http-redirect-port 19800


## References

  - [Re: Can I use lighttpd/nginx for webdav but have updated disk usage statistics for mogile?](http://www.mail-archive.com/mogilefs@lists.danga.com/msg00366.html)

