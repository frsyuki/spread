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
require 'pp'

def usage
	puts "Usage: #{File.basename($0)} <cs address[:port]> <command> [options]"
	puts "command:"
	puts "   stat                         show statistics of nodes"
	puts "   nodes                        show list of nodes"
	puts "   remove_node <nid>            remove a node from the cluster"
	puts "   weight                       show list of replication sets"
	puts "   set_weight <rsid> <weight>   set distribution weight"
	puts "   mds                          show MDS uri"
	puts "   set_mds <URI>                set MDS uri"
	puts "   mds_cache                    show MDS cache uri"
	puts "   set_mds_cache <URI>          set MDS cache uri"
	puts "   items                        show stored number of items"
	puts "   version                      show software version of nodes"
	puts "   locate <key>                 show which servers store the key"
	exit 1
end

if ARGV.length < 2
	usage
end

$net = MessagePack::RPC::SessionPool.new
addr = ARGV.shift
host, port = addr.split(':', 2)
port = port.to_i
port = 18700 if port == 0
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
	#start = Time.now

	s = $net.get_session(*$addr)
	s.timeout = 20
	result = s.call(*args)
	if klass && result
		result = klass.new.from_msgpack(result)
	end

	#finish = Time.now
	#puts "#{finish - start} sec."

	result
end

Node = Struct.new('Node', :nid, :address, :name, :rsids, :location)

def get_nodes
	call(nil, :stat, 'nodes').map {|nid,address,name,rsids,location|
		address = MessagePack::RPC::Address.load(address)
		Node.new(nid, address, name, rsids, location)
	}.sort_by {|node|
		node.nid
	}
end

def get_node_map
	map = {}
	call(nil, :stat, 'nodes').each {|nid,address,name,rsids|
		address = MessagePack::RPC::Address.load(address)
		map[nid] = [address, name, rsids]
	}
	map
end

def each_node(&block)
	get_nodes.map {|node|
		result = yield($net.get_session(node.address), node)
		[node, result]
	}
end

case cmd
when 'nodes'
	cmd_args(0)

	fault_nids = call(nil, :stat, 'fault')

	NODES_FORMAT = "%3s %15s %23s %23s %7s %10s"
	puts NODES_FORMAT % %w[nid name address location rsid state]

	each_node {|s,node|
		rsids = node.rsids.sort.join(',')
		state = fault_nids.include?(node.nid) ? 'FAULT' : 'active'
		puts NODES_FORMAT % [node.nid, node.name, node.address, node.location, rsids, state]
	}

when 'remove_node'
	nid_s = cmd_args(1)
	nid = nid_s.to_i
	if nid.to_s != nid_s
		raise "invalid nid: #{nid}"
	end
	pp call(nil, :remove_node, nid)

when 'weight'
	cmd_args(0)
	REPLSET_FORMAT = "%4s %8s %10s   %s"
	puts REPLSET_FORMAT % %w[rsid weight nids names]
	node_map = get_node_map
	rsid_replset = call(nil, :stat, 'replset').sort_by {|rsid,(nids,weight)|
		if nids.empty?
			rsid += (2<<16)
		end
		rsid
	}
	rsid_replset.each {|rsid,(nids,weight)|
		names = nids.map {|nid| node_map[nid][1] }.join(',')
		nids = nids.sort.join(',')
		puts REPLSET_FORMAT % [rsid, weight, nids, names]
	}

when 'set_weight'
	rsid_s, weight_s = cmd_args(2)
	rsid = rsid_s.to_i
	weight = weight_s.to_i
	if rsid.to_s != rsid_s
		raise "invalid rsid: #{rsid}"
	end
	if weight.to_s != weight_s
		raise "invalid weight: #{weight}"
	end
	pp call(nil, :set_replset_weight, rsid, weight)

when 'reset_weight'
	rsid_s = cmd_args(1)
	rsid = rsid_s.to_i
	if rsid.to_s != rsid_s
		raise "invalid rsid: #{rsid}"
	end
	pp call(nil, :reset_replset_weight, rsid)

when 'mds'
	cmd_args(0)
	uri = call(nil, :get_mds_uri)
	puts uri

when 'set_mds'
	uri = cmd_args(1)
	pp call(nil, :set_mds_uri, uri)

when 'mds_cache'
	cmd_args(0)
	uri = call(nil, :get_mds_cache_uri)
	if !uri || uri.empty?
		puts "null"
	else
		puts uri
	end

when 'set_mds_cache'
	uri = cmd_args(1)
	pp call(nil, :set_mds_cache_uri, uri)

when 'stat', 'status'
	STAT_FORMAT = "%4s %15s %10s %10s %10s %10s %30s"
	puts STAT_FORMAT % %w[nid name uptime #read #write #delete time]
	each_node {|s,node|
		f_uptime = s.call_async(:stat, 'uptime')     rescue nil
		f_read   = s.call_async(:stat, 'cmd_read')   rescue nil
		f_write  = s.call_async(:stat, 'cmd_write')  rescue nil
		f_delete = s.call_async(:stat, 'cmd_delete') rescue nil
		f_time   = s.call_async(:stat, 'time')       rescue nil
		[f_uptime, f_read, f_write, f_delete, f_time]
	}.each {|node,(f_uptime,f_read,f_write,f_delete,f_time)|
		uptime = f_uptime.get rescue nil
		read   = f_read.get   rescue nil
		write  = f_write.get  rescue nil
		delete = f_delete.get rescue nil
		time   = f_time.get   rescue nil
		time &&= Time.at(time).localtime
		puts STAT_FORMAT % [node.nid, node.name, uptime, read, write, delete, time]
	}

when 'items'
	ITEMS_FORMAT = "%4s %15s %10s %10s"
	puts ITEMS_FORMAT % %w[nid name rsid #items]

	map = {}
	each_node {|s,node|
		f_items = s.call_async(:stat, 'db_items')
		[f_items]
	}.each {|node,(f_items)|
		items = f_items.get rescue nil
		rsids = node.rsids.sort.join(',')
		puts ITEMS_FORMAT % [node.nid, node.name, rsids, items]

		items ||= 0
		node.rsids.each {|rsid|
			if !map[rsid] || map[rsid] < items
				map[rsid] = items
			end
		}
	}

	total = map.values.inject(0) {|r,n| r + n }
	puts "total: #{total}"

when 'version'
	VERSION_FORMAT = "%4s %15s %10s %10s"
	puts VERSION_FORMAT % %w[nid name pid version]

	each_node {|s,node|
		f_pid = s.call_async(:stat, 'pid')
		f_version = s.call_async(:stat, 'version')
		[f_pid, f_version]
	}.each {|node,(f_pid,f_version)|
		pid = f_pid.get rescue nil
		version = f_version.get rescue nil
		puts VERSION_FORMAT % [node.nid, node.name, pid, version]
	}

when 'locate'
	key = cmd_args(1)

	nodes = get_nodes

	gwnode = nodes.first
	vers = $net.get_session(*gwnode.address).call(:util_locate, key)

	if vers.empty?
		$stderr.puts "not found."
		exit 0
	end

	NODE_FORMAT = "   > %-15s nid=%-3s %23s %23s"

	vers.each {|(key,vtime,rsid),vname|
		time = Time.at(vtime)
		puts "vtime=[#{time}]  vname=#{vname.inspect}\trsid=#{rsid}:"
		nodes.each {|node|
			if node.rsids.include?(rsid)
				puts NODE_FORMAT % [node.name, node.nid, node.address, node.location]
			end
		}
	}

else
	puts "unknown command #{cmd}"
	puts ""
	usage
end

