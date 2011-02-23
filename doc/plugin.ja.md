プラグインリファレンス - SpreadOSD
==================================

## ストレージプラグイン

DS (Data Server) の *--store* 引数にスキーマを指定することで、ストレージの実装を選択することができます。デフォルトはDirectory Storageです。

### Directory Storage (dir:)

ディレクトリをストレージとして使用します。

スキーマは **dir:&lt;path&gt;** です。


## MDSプラグイン

CS (Config Server) の *--mds* 引数にスキーマを指定することで、MDS (Metadata Server) の実装を選択することができます。デフォルトはTokyo Tyrantです。

### Tokyo Tyrant (tt:)

[Tokyo Tyrant](http://fallabs.com/tokyotyrant/) のテーブルデータベースをMDSとして使用します。
バージョニングをサポートしています。

スキーマは **tt:&lt;servers&gt;[;&lt;weights&gt;]** です。


### Memcache (mc:)

memcachedプロトコルをMDSとして使用します。
バージョニングはサポートしていません。

このプラグインはmemcachedプロトコルをサポートした永続的なストレージを使用することを意図しています。例えば[Kumofs](http://kumofs.sourceforge.net/)、[Flare](http://labs.gree.jp/Top/OpenSource/Flare-en.html)、[Membase](http://www.membase.org/)などです。memcachedは使わないでください。

スキーマは **mc:&lt;servers&gt;[;&lt;weights&gt;]** です。


## MDSキャッシュプラグイン

GW (Gateway) または DS (Data Server) に *--mds-cache* 引数を指定することで、メタデータのキャッシュを有効にすることができます。

### Memcached (mc:)

[memcached](http://memcached.org/) をMDSキャッシュとして使用します。

スキーマは **mc:&lt;servers&gt;[;&lt;expire&gt;]** です。


### Local memory (lcoal:)

ローカルメモリをMDSキャッシュとして使用します。
キャッシュは共有されないので、更新系のAPIは一貫性の問題を引き起こすかもしれません。

スキーマは **local:&lt;size&gt;** です。


