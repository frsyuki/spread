#!/usr/bin/env ruby

begin
require 'rubygems'
rescue LoadError
end
require 'msgpack'
require 'msgpack/rpc'
require 'irb'

def call(method, *args)
	cli = MessagePack::RPC::Client.new(Host, Port)
	begin
		cli.timeout = 5
		cli.call(method, *args)
	ensure
		cli.close
	end
end

module SpreadRPC
	CS_METHODS = []
	DS_METHODS = []
	GW_METHODS = []

	def self.rpc(name, args)
		self.module_eval <<-RUBY
			def #{name}(#{args.join(',')})
				call(:#{([name]+args).join(',')})
			end
		RUBY
	end

	def self.cs_rpc(name, *args)
		CS_METHODS << [name, args]
		rpc(name, args)
	end

	def self.ds_rpc(name, *args)
		DS_METHODS << [name, args]
		rpc(name, args)
	end

	def self.gw_rpc(name, *args)
		GW_METHODS << [name, args]
		rpc(name, args)
	end

	def show
		puts "Gateway methods:"
		GW_METHODS.each {|name,args|
			puts "  #{name}(#{args.join(', ')})"
		}
		puts ""
		puts "Config Server methods:"
		CS_METHODS.each {|name,args|
			puts "  #{name}(#{args.join(', ')})"
		}
		puts ""
		puts "Data Server methods:"
		(DS_METHODS+GW_METHODS).each {|name,args|
			puts "  #{name}(#{args.join(', ')})"
		}
		nil
	end

	gw_rpc :get, :key
	gw_rpc :get_data, :key
	gw_rpc :get_attrs, :key
	gw_rpc :read, :key, :offset, :size
	gw_rpc :gett, :vtime, :key
	gw_rpc :gett_data, :vtime, :key
	gw_rpc :gett_attrs, :vtime, :key
	gw_rpc :readt, :vtime, :key, :offset, :size
	gw_rpc :getv, :vname, :key
	gw_rpc :getv_data, :vname, :key
	gw_rpc :getv_attrs, :vname, :key
	gw_rpc :readv, :vname, :key, :offset, :size
	gw_rpc :getd_data, :okey
	gw_rpc :readd, :okey, :offset, :size
	gw_rpc :add, :key, :data, :attrs
	gw_rpc :add_data, :key, :data
	gw_rpc :addv, :vname, :key, :data, :attrs
	gw_rpc :addv_data, :vname, :key, :data
	gw_rpc :update_attrs, :key, :attrs
	gw_rpc :remove, :key
	gw_rpc :delete, :key
	gw_rpc :deletet, :vtime, :key
	gw_rpc :deletev, :vname, :key
	gw_rpc :url, :key
	gw_rpc :urlt, :vtime, :key
	gw_rpc :urlv, :vname, :key
	gw_rpc :util_locate, :key
	gw_rpc :stat, :cmd

	cs_rpc :heartbeat, :nid, :sync_hash
	cs_rpc :sync_config, :hash_array
	cs_rpc :add_node, :nid, :address, :name, :rsids, :self_location
	cs_rpc :remove_node, :nid
	cs_rpc :update_node_info, :nid, :address, :name, :rsids
	cs_rpc :recover_node, :nid
	cs_rpc :set_replset_weight, :rsid, :weight
	cs_rpc :reset_replset_weight, :rsid
	cs_rpc :get_mds_uri
	cs_rpc :set_mds_uri, :uri
	cs_rpc :get_mds_cache_uri
	cs_rpc :set_mds_cache_uri, :uri
	cs_rpc :stat, :cmd

	ds_rpc :get_direct, :okey
	ds_rpc :set_direct, :okey, :data
	ds_rpc :delete_direct, :okey
	ds_rpc :read_direct, :okey, :offset, :size
	ds_rpc :url_direct, :okey
	ds_rpc :resize_direct, :okey, :size
	ds_rpc :replicate_pull, :pos, :limit
	ds_rpc :replicate_notify, :nid
end

def usage_exit
	puts "usage: #{File.basename($0)} <host>:<port> [method [args ...]]"
	exit 1
end

if ARGV.length < 1
	usage_exit
end

host, port = ARGV.shift.split(':')
port = port.to_i
if port == 0
	usage_exit
end

Host = host
Port = port

include SpreadRPC

if ARGV.empty?
	puts "Type 'show' to show all supported RPC methods."
	IRB.start

else
	require 'pp'
	require 'yaml'
	require 'json'
	method = ARGV.shift
	args = ARGV.map {|arg|
		YAML.load(arg)
	}
	puts SpreadRPC.method(method).call(*args).to_json

end

