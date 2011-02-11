SpreadOSD APIリファレンス
========================

## HTTP API

### GET /data/&lt;key&gt;

オブジェクトのデータを取得します。

オブジェクトが見つかった場合はステータスコード*200 OK*で返り、*application/octet-stream*のデータを返します。
オブジェクトが見つからなかった場合はステータスコード*404 Not Found*で返ります。

次のパラメータを指定することができます：

  - *vtime=&lt;integer&gt;* 取得するオブジェクトのバージョンを世界協定時（UTC）のUNIX時刻で指定します。この時刻以前に作成された最新のバージョンを返します。*vname=*と同時に指定することはできません。
  - *vname=&lt;string&gt;* 取得するオブジェクトのバージョンを名前で指定します。指定した名前に一致するバージョンを返します。*vtime=*と同時に指定することはできません。


### POST /data/&lt;key&gt;

オブジェクトを追加します。

成功した場合はステータスコード*200 OK*で返ります。

次のパラメータを指定することができます：

  - *data=&lt;bytes&gt;* 追加するデータ本体を設定します。このパラメータは必須です。
  - *vname=&lt;string&gt;* 追加するオブジェクトのバージョン名を設定します。
  - *attrs=&lt;format&gt;* オブジェクトの属性を設定します。属性は*format=*で指定した形式でエンコードします。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。*attrs=* が指定されているときだけ有効です。json (JSON)、msgpack (MessagePack)、tsv (Tab-separated values) を指定することができます。デフォルトは json です。


### PUT /data/&lt;key&gt;

オブジェクトを追加します。

動作はPOSTと同じでが、成功した場合はステータスコード*202 Accepted*で返ります。


### GET /attrs/&lt;key&gt;

オブジェクトの属性を取得します。

成功した場合はステータスコード*200 OK*で返り、*form=*パラメータで指定された形式でエンコードされたデータを返します。

次のパラメータを指定することができます：

  - *vtime=&lt;integer&gt;* 取得するオブジェクトのバージョンを世界協定時（UTC）のUNIX時刻で指定します。この時刻以前に作成された最新のバージョンを返します。*vname=*と同時に指定することはできません。
  - *vname=&lt;string&gt;* 取得するオブジェクトのバージョンを名前で指定します。指定した名前に一致するバージョンを返します。*vtime=*と同時に指定することはできません。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。json (JSON; application/json)、msgpack (MessagePack; application/x-msgpack)、tsv (Tab-separated values; text/tab-separated-values) を指定することができます。デフォルトは json です。


### POST /attrs/&lt;key&gt;

オブジェクトの属性を上書きして更新します。

オブジェクトが見つかった場合はステータスコード*200 OK*で返ります。
オブジェクトが見つからなかった場合はステータスコード*404 Not Found*で返ります。

次のパラメータを指定することができます：

  - *attrs=&lt;format&gt;* オブジェクトの属性を設定します。属性は*format=*で指定した形式でエンコードします。このパラメータは必須です。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。*attrs=* が指定されているときだけ有効です。json (JSON)、msgpack (MessagePack)、tsv (Tab-separated values) を指定することができます。デフォルトは json です。


### GET /api/get\_data

オブジェクトのデータを取得します。

オブジェクトが見つかった場合はステータスコード*200 OK*で返り、*application/octet-stream*のデータを返します。
オブジェクトが見つからなかった場合はステータスコード*404 Not Found*で返ります。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 取得するオブジェクトのキーを設定します。このパラメータは必須です。
  - *vtime=&lt;integer&gt;* 取得するオブジェクトのバージョンを世界協定時（UTC）のUNIX時刻で指定します。この時刻以前に作成された最新のバージョンを返します。*vname=*と同時に指定することはできません。
  - *vname=&lt;string&gt;* 取得するオブジェクトのバージョンを名前で指定します。指定した名前に一致するバージョンを返します。*vtime=*と同時に指定することはできません。


### GET /api/get\_attrs

オブジェクトの属性を取得します。

成功した場合はステータスコード*200 OK*で返り、*form=*パラメータで指定された形式でエンコードされたデータを返します。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 取得するオブジェクトのキーを設定します。このパラメータは必須です。
  - *vtime=&lt;integer&gt;* 取得するオブジェクトのバージョンを世界協定時（UTC）のUNIX時刻で指定します。この時刻以前に作成された最新のバージョンを返します。*vname=*と同時に指定することはできません。
  - *vname=&lt;string&gt;* 取得するオブジェクトのバージョンを名前で指定します。指定した名前に一致するバージョンを返します。*vtime=*と同時に指定することはできません。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。json (JSON; application/json)、msgpack (MessagePack; application/x-msgpack)、tsv (Tab-separated values; text-tab-separated-values) を指定することができます。デフォルトは json です。


### POST /api/add

オブジェクトを追加します。

成功した場合はステータスコード*200 OK*で返ります。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 追加するオブジェクトのキーを設定します。このパラメータは必須です。
  - *data=&lt;bytes&gt;* 追加するデータ本体を設定します。このパラメータは必須です。
  - *vname=&lt;string&gt;* 追加するオブジェクトのバージョン名を設定します。
  - *attrs=&lt;format&gt;* オブジェクトの属性を設定します。属性は*format=*で指定した形式でエンコードします。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。*attrs=* が指定されているときだけ有効です。json (JSON)、msgpack (MessagePack)、tsv (Tab-separated values) を指定することができます。デフォルトは json です。


### POST /api/update\_attrs

オブジェクトの属性を上書きして更新します。

成功した場合はステータスコード*200 OK*で返ります。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 追加するオブジェクトのキーを設定します。このパラメータは必須です。
  - *attrs=&lt;bytes&gt;* 属性本体を設定します。このパラメータは必須です。
  - *attrs=&lt;format&gt;* オブジェクトの属性を設定します。属性は*format=*で指定した形式でエンコードします。
  - *format=&lt;string&gt;* 属性のエンコード形式を指定します。*attrs=* が指定されているときだけ有効です。json (JSON)、msgpack (MessagePack)、tsv (Tab-separated values) を指定することができます。デフォルトは json です。


### POST /api/remove

オブジェクトを削除します。

削除に成功した場合はステータスコード*200 OK*で返ります。
オブジェクトが存在しなかった場合はステータスコード*404 Not Found*で返ります。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 削除するオブジェクトのキーを設定します。このパラメータは必須です。


### GET /api/url

オブジェクトが実際に保存されている DS (Data Server) を1つ選択し、そこから直接データを取得するためのURLを取得します。DSに*--http*引数か*--http-redirect-port*引数が設定されている場合にのみ有効です。

オブジェクトが見つかった場合はステータスコード*200 OK*で返り、*text/plain*形式でURLを返します。
オブジェクトが見つからなかった場合はステータスコード*404 Not Found*で返ります。

次のパラメータを指定することができます：

  - *key=&lt;string&gt;* 取得するオブジェクトのキーを設定します。このパラメータは必須です。
  - *vtime=&lt;integer&gt;* 取得するオブジェクトのバージョンを世界協定時（UTC）のUNIX時刻で指定します。この時刻以前に作成された最新のバージョンを返します。*vname=*と同時に指定することはできません。
  - *vname=&lt;string&gt;* 取得するオブジェクトのバージョンを名前で指定します。指定した名前に一致するバージョンを返します。*vtime=*と同時に指定することはできません。

参考：[NginxのX-Accel-Redirectを使って直接データを転送する](howto/nginx.ja.md)


### GET /redirect/&lt;key&gt;

GET /api/url?key=&lt;key&gt; と似ていますが、オブジェクトが実際に見つかった場合はステータスコード*302 Found*で返り、*Location:*ヘッダを使ってリダイレクトします。

参考：[NginxのX-Accel-Redirectを使って直接データを転送する](howto/nginx.ja.md)


## MessagePack-RPC API

<!--
TODO
-->

### 取得API

#### get(key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

オブジェクトのデータと属性を取得します。


#### get\_data(key:Raw) -&gt; data:Raw

オブジェクトのデータを取得します。


#### get\_attrs(key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

オブジェクトの属性を取得します。


#### read(key:Raw, offset:Integer, size:Integer) -&gt; data:Raw

オブジェクトのデータの一部を取得します。


### バージョン指定付きの取得API

#### gett(vtime:Integer, key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

時刻を指定して、オブジェクトのデータを取得します。指定した時刻以前に作成された最新のバージョンを返します。


#### gett\_data(vtime:Integer, key:Raw) -&gt; data:Raw

時刻を指定して、オブジェクトのデータを取得します。指定した時刻以前に作成された最新のバージョンを返します。


#### gett\_attrs(vtime:Integer, key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

時刻を指定して、オブジェクトの属性を取得します。指定した時刻以前に作成された最新のバージョンを返します。


#### readt(vtime:Integer, key:Raw, offset:Integer, size:Integer) -&gt; data:Raw

時刻を指定して、オブジェクトのデータの一部を取得します。指定した時刻以前に作成された最新のバージョンを返します。


#### getv(vname:Raw, key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

バージョン名を指定して、オブジェクトのデータと属性を取得します。指定した名前に一致するバージョンを返します。


#### getv\_data(vname:Raw, key:Raw) -&gt; data:Raw

バージョン名を指定して、オブジェクトのデータを取得します。指定した名前に一致するバージョンを返します。


#### getv\_attrs(vname:Raw, key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

バージョン名を指定して、オブジェクトの属性を取得します。指定した名前に一致するバージョンを返します。


#### readv(vname:Raw, key:Raw, offset:Integer, size:Integer) -&gt; data:Raw

バージョン名を指定して、オブジェクトのデータの一部を取得します。指定した名前に一致するバージョンを返します。


### 追加API

#### add(key:Raw, data:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object

オブジェクトを追加します。バージョン名は空になります。


#### add\_data(key:Raw, data:Raw) -&gt; objectKey:Object

オブジェクトを追加します。属性は空の連想配列になります。バージョン名は空になります。


#### addv(vname:Raw, key:Raw, data:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object

バージョン名を指定してオブジェクトを追加します。


#### addv\_data(vname:Raw, key:Raw, data:Raw) -&gt; objectKey:Object

バージョン名を指定してオブジェクトを追加します。属性は空の連想配列になります。


### 削除API

#### remove(key:Raw)

オブジェクトを削除します。


### 上書き更新API

#### update\_attrs(key:Raw, attributes:Map&lt;Raw,Raw&gt;)

オブジェクトの属性を上書きして更新します。


### 直接取得API

#### getd\_data(objectKey:Object) -&gt; data:Raw

MDSに問い合わせをせずに、データを取得します。


#### readd(objectKey:Object, offset:Integer, size:Integer) -&gt; data:Raw

MDSに問い合わせをせずに、データの一部を取得します。


