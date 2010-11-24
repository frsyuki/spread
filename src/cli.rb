#
#  SpreadOSD
#  Copyright (C) 2010  FURUHASHI Sadayuki
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'msgpack/rpc'
require 'json'
require 'pp'

def usage
	puts "Usage: #{File.basename($0)} <address[:port]> <command> [options]"
	puts "command:"
	puts "   set <key> <json>                 set a map"
	puts "   get <key>                        get the map and show json"
	puts "   remove <key>                     remove the map"
	puts "   get_data <key>                   get the map and show map[\"data\"]"
	puts "   set_data <key> <data>            set a map {\"data\":data}"
	puts "   get_direct <rsid> <key>          get the data from the replication set directly"
	puts "   set_direct <rsid> <key> <data>   set the data to the replication set directly"
	puts "   remove_direct <rsid> <key>       remove the data from the replication set directly"
	exit 1
end

if ARGV.length < 2
	usage
end

$net = MessagePack::RPC::SessionPool.new
addr = ARGV.shift
host, port = addr.split(':', 2)
port = port.to_i
port = 18800 if port == 0
$addr = [host,port]#Address.new(host, port)

cmd = ARGV.shift

def cmd_args(n)
	if n < 0
		return ARGV
	end
	usage if ARGV.length != n
	ARGV.map! {|ar| ar == '-' ? $stdin.read : ar }
	if n == 1
		ARGV[0]
	else
		ARGV
	end
end

def call(klass, *args)
	start = Time.now

	result = $net.get_session(*$addr).call(*args)
	if klass && result
		result = klass.new.from_msgpack(result)
	end

	finish = Time.now
	puts "#{finish - start} sec."

	result
end

case cmd
when 'get'
	key = cmd_args(1)
	map = call(nil, :get, key)
	if map
		puts map.to_json
	else
		puts "nil"
	end

when 'set'
	key, json = cmd_args(2)
	map = JSON.parse(json)
	pp call(nil, :set, key, map)

when 'remove'
	key = cmd_args(1)
	pp call(nil, :remove, key)

when 'get_data'
	key = cmd_args(1)
	map = call(nil, :get, key)
	if map
		data = map["data"]
		size = (data || "").size
		puts "#{size} bytes"
	else
		pp nil
	end

when 'set_data'
	key, data = cmd_args(2)
	pp call(nil, :set, key, {"data"=>data})

when 'get_direct'
	rsid, key = cmd_args(2)
	rsid = rsid.to_i
	data = call(nil, :get_direct, key, rsid)
	pp data

when 'set_direct'
	rsid, key, data = cmd_args(3)
	rsid = rsid.to_i
	pp call(nil, :set_direct, key, rsid, data)

when 'remove_direct'
	rsid, key = cmd_args(2)
	rsid = rsid.to_i
	pp call(nil, :remove_direct, key, rsid)

else
	puts "unknown command #{cmd}"
	puts ""
	usage
end

