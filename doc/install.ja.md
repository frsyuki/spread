SpreadOSD インストール
======================

SpreadOSDはRubyで実装された分散ストレージシステムです。
make installでインストールするか、RubyGemsを使ってインストールすることができます。


## 依存ライブラリ

SpreadOSDを実行するには次のソフトウェアが必要です：

  - [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) &gt;= 1.4.40
  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) &gt;= 1.1.40
  - [ruby](http://www.ruby-lang.org/) &gt;= 1.9.2
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) &gt;= 0.4.3
  - [tokyocabinet gem](http://rubygems.org/gems/tokyocabinet) &gt;= 1.29
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) &gt;= 1.13
  - [memcache-client gem](http://rubygems.org/gems/memcache-client) &gt;= 1.8.5
  - [rack gem](http://rubygems.org/gems/rack) &gt;= 1.2.1


## 方法1：RubyGemsを使ったインストール

1つ目のインストール方法は、rake と gem を使う方法です：

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

もしRubyを広く使っているのであれば、RubyGemsを使ってバージョンを管理するのが良い方法でしょう。

## 方法2：make installを使ったインストール

もう1つの方法は、./configure && make install を使う方法です：

    $ ./bootstrap  # 必要な場合
    $ ./configure RUBY=/usr/local/bin/ruby
    $ make
    $ sudo make install

以下のコマンドがインストールされます：

  - spreadctl: 管理ツール
  - spreadcli: コマンドラインクライアント
  - spread-cs: CSサーバプログラム
  - spread-ds: DSサーバプログラム
  - spread-gw: GWサーバプログラム


## 専用のRuby 1.9をインストールする

ここでは /opt/local/spread ディレクトリに全システムをコンパイルしてインストールします。

まず、以下のパッケージをパッケージ管理ツールを使ってインストールしてください：

  - gcc-g++ &gt;= 4.1
  - openssl-devel (or libssl-dev) to build ruby
  - zlib-devel (or zlib1g-dev) to build ruby
  - readline-devel (or libreadline6-dev) to build ruby
  - tokyocabinet (or libtokyocabinet-dev) to build Tokyo Tyrant

以下の手順でRubyとSpreadOSDをインストールします：

    # Installs ruby-1.9 into /opt/local/spread
    $ wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p0.tar.bz2
    $ tar jxvf ruby-1.9.2-p0.tar.bz2
    $ cd ruby-1.9.2
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # Installs required gems
    $ sudo /opt/local/spread/bin/gem install msgpack-rpc
    $ sudo /opt/local/spread/bin/gem install tokyocabinet
    $ sudo /opt/local/spread/bin/gem install tokyotyrant
    $ sudo /opt/local/spread/bin/gem install memcache-client
    $ sudo /opt/local/spread/bin/gem install rack
    
    # Installs SpreadOSD
    $ git clone http://github.com/frsyuki/spread.git
    $ cd spread
    $ ./configure RUBY=/opt/local/spread/bin/ruby --prefix=/opt/local/spread
    $ make
    $ sudo make install
    
    # Installs Tokyo Tyrant into /opt/local/spread
    $ wget http://fallabs.com/tokyotyrant/tokyotyrant-1.1.41.tar.gz
    $ tar zxvf tokyotyrant-1.1.41.tar.gz
    $ cd tokyotyrant-1.1.41
    $ ./configure --prefix=/opt/local/spread
    $ make
    $ sudo make install

