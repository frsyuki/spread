API Reference - SpreadOSD
=========================

## HTTP API

### GET /data/&lt;key&gt;

Gets data of the object.

If the object is found, it returns status code *200 OK* and *application/octet-stream* data.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *vtime=&lt;integer&gt;* Specify version of the object by UNIX time at UTC. It returns the latest version created before the time. This parameter can't be used with *vname=*.
  - *vname=&lt;string&gt;* Specify version of the object by name. This parameter can't be used with *vtime=*.


### POST /data/&lt;key&gt;

Adds a object.

If it succeeded, it returns status code *200 OK*.

Following parameters are acceptable:

  - *data=&lt;bytes&gt;* Sets the data. This parameter is required.
  - *vname=&lt;string&gt;* Sets the version name of the object.
  - *attrs=&lt;format&gt;* Sets the attributes of the object. Encode this parameter using the format specified with *format=* parameter.
  - *format=&lt;string&gt;* Sets the format of the *attrs=* option. This parameter is valid only when *attrs=* parameter is specified. You can use json (JSON), msgpack (MessagePack) or tsv (Tab-separated values). The default value is json.


### PUT /data/&lt;key&gt;

Adds a object.

This is same as POST excluding this returns status code *200* when it succeeded.


### GET /attrs/&lt;key&gt;

Gets attributes of the object.

If the object is found, it returns status code *200 OK* and attributes encoded by format specified with *format=* parameter.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *vtime=&lt;integer&gt;* Specify version of the object by UNIX time at UTC. It returns the latest version created before the time. This parameter can't be used with *vname=*.
  - *vname=&lt;string&gt;* Specify version of the object by name. This parameter can't be used with *vtime=*.
  - *format=&lt;string&gt;* Specify the format of the attributes to be returned. You can use json (JSON; application/json), msgpack (MessagePack; application/x-msgpack) or tsv (Tab-separated values; text/tab-separated-values). The default value is json.


### POST /attrs/&lt;key&gt;

Overwrites attributes of the object.

If the object is found, it returns status code *200 OK* and *application/octet-stream* data.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *attrs=&lt;format&gt;* Sets the attributes. This parameter is required.
  - *format=&lt;string&gt;* Sets the format of the *attrs=* option. You can use json (JSON), msgpack (MessagePack) or tsv (Tab-separated values). The default value is json.


### GET /api/get\_data

Gets data of the object.

If the object is found, it returns status code *200 OK* and *application/octet-stream* data.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.
  - *vtime=&lt;integer&gt;* Specify version of the object by UNIX time at UTC. It returns the latest version created before the time. This parameter can't be used with *vname=*.
  - *vname=&lt;string&gt;* Specify version of the object by name. This parameter can't be used with *vtime=*.


### GET /api/get\_attrs

Gets attributes of the object.

If the object is found, it returns status code *200 OK* and attributes encoded by format specified with *format=* parameter.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.
  - *vtime=&lt;integer&gt;* Specify version of the object by UNIX time at UTC. It returns the latest version created before the time. This parameter can't be used with *vname=*.
  - *vname=&lt;string&gt;* Specify version of the object by name. This parameter can't be used with *vtime=*.
  - *format=&lt;string&gt;* Specify the format of the attributes to be returned. You can use json (JSON; application/json), msgpack (MessagePack; application/x-msgpack) or tsv (Tab-separated values; text/tab-separated-values). The default value is json.


### POST /api/add

Adds a object.

If it succeeded, it returns status code *200 OK*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.
  - *data=&lt;bytes&gt;* Sets the data. This parameter is required.
  - *vname=&lt;string&gt;* Sets the version name of the object.
  - *attrs=&lt;format&gt;* Sets the attributes of the object. Encode this parameter using the format specified with *format=* parameter.
  - *format=&lt;string&gt;* Sets the format of the *attrs=* option. This parameter is valid only when *attrs=* parameter is specified. You can use json (JSON), msgpack (MessagePack) or tsv (Tab-separated values). The default value is json.


### POST /api/update\_attrs

Overwrites attributes of the object.

If the object is found, it returns status code *200 OK* and *application/octet-stream* data.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.
  - *attrs=&lt;format&gt;* Sets the attributes. This parameter is required.
  - *format=&lt;string&gt;* Sets the format of the *attrs=* option. You can use json (JSON), msgpack (MessagePack) or tsv (Tab-separated values). The default value is json.


### POST /api/remove

Removes the object

If it succeeded, it returns status code *200 OK*.
If it is not found, it returns status code *204 Not Found*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.


### GET /api/url

Selects a data server (DS) which stores the data, and returns URL to get the data directly from the DS. This is valid only when *--http* option or *--http-redirect-port* option is specified on the DS.

If the object is found, it returns status code *200 OK* and URL in *text/plain* format.
If the object is not found, it returns status code *404 Not Found*.

Following parameters are acceptable:

  - *key=&lt;string&gt;* Specify the key of the object. This parameters is required.
  - *vtime=&lt;integer&gt;* Specify version of the object by UNIX time at UTC. It returns the latest version created before the time. This parameter can't be used with *vname=*.
  - *vname=&lt;string&gt;* Specify version of the object by name. This parameter can't be used with *vtime=*.

TODO: See Direct data transfer with X-Accel-Redirect


### GET /redirect/&lt;key&gt;

This is similar to GET /api/url?key=&lt;key&gt;, but this returns status code *302 Found* and redirects using *Location:* header.

TODO: See Direct data transfer with X-Accel-Redirect


## MessagePack-RPC API

TODO

### Getting API

#### get(key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

Gets data and attributes of the object.


#### get\_data(key:Raw) -&gt; data:Raw

Gets data of the object.


#### get\_attrs(key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

Gets attributes of the object.


#### read(key:Raw, offset:Integer, size:Integer) -&gt; data:Raw

Gets a part data of the object.


### Getting specific version API

#### gett(vtime:Integer, key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

#### gett\_data(vtime:Integer, key:Raw) -&gt; data:Raw

#### gett\_attrs(vtime:Integer, key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

#### readt(vtime:Integer, key:Raw, offset:Integer, size:Integer) -&gt; data:Raw


#### getv(vname:Raw, key:Raw) -&gt; [data:Raw, attributes:Map&lt;Raw,Raw&gt;]

#### getv\_data(vname:Raw, key:Raw) -&gt; data:Raw

#### getv\_attrs(vname:Raw, key:Raw) -&gt; attributes:Map&lt;Raw,Raw&gt;

#### readv(vname:Raw, key:Raw, offset:Integer, size:Integer) -&gt; data:Raw


### Adding API

#### add(key:Raw, data:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object

#### add\_data(key:Raw, data:Raw) -&gt; objectKey:Object

#### addv(vname:Raw, key:Raw, data:Raw, attributes:Map&lt;Raw,Raw&gt;) -&gt; objectKey:Object

#### addv\_data(vname:Raw, key:Raw, data:Raw) -&gt; objectKey:Object


### Removing API

#### remove(key:Raw)


### In-place updating API

#### update\_attrs(key:Raw, attributes:Map&lt;Raw,Raw&gt;)


### Direct getting API

#### getd\_data(objectKey:Object) -&gt; data:Raw

#### readd(objectKey:Object, offset:Integer, size:Integer) -&gt; data:Raw


