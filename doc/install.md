Installation - SpreadOSD
========================

SpreadOSD is a distributed storage system implemed in Ruby.
You can install using *make install* or using RubyGems.


## Requirements

Following softwares are required to run SpreadOSD:

  - [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) &gt;= 1.4.40
  - [Tokyo Tyrant](http://fallabs.com/tokyotyrant/) &gt;= 1.1.40
  - [ruby](http://www.ruby-lang.org/) &gt;= 1.9.1
  - [msgpack-rpc gem](http://rubygems.org/gems/msgpack-rpc) &gt;= 0.4.3
  - [tokyocabinet gem](http://rubygems.org/gems/tokyocabinet) &gt;= 1.29
  - [tokyotyrant gem](http://rubygems.org/gems/tokyotyrant) &gt;= 1.13
  - [memcache-client gem](http://rubygems.org/gems/memcache-client) &gt;= 1.8.5
  - [rack gem](http://rubygems.org/gems/rack) &gt;= 1.2.1


## Choice 1: Install using RubyGems

One way is to use rake and gem:

    $ rake
    $ gem install pkg/spread-osd-<version>.gem

If your site uses Ruby widely, RubyGems will be good choice to manage version of softwares.

## Choice 2: Install using make-install

The other way is to use ./configure && make install:

    $ ./bootstrap  # if needed
    $ ./configure RUBY=/usr/local/bin/ruby
    $ make
    $ sudo make install

Following commands will be installed:

  - spreadctl: Management tool
  - spreadcli: Command line client
  - spread-cs: CS server program
  - spread-ds: DS server program
  - spread-gw: GW server program

## Compiling Ruby 1.9 for exclusive use

In this guide, you will install all systems on /opt/local/spread directory.

First, install folowing packages using the package management system:

  - gcc-g++ &gt;= 4.1
  - openssl-devel (or libssl-dev) to build Ruby
  - zlib-devel (or zlib1g-dev) to build Ruby
  - readline-devel (or libreadline6-dev) to build Ruby
  - tokyocabinet (or libtokyocabinet-dev) to build Tokyo Tyrant

Following procedure installs Ruby and SpreadOSD:

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

