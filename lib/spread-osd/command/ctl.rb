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
	puts "Usage: #{File.basename($0)} <address[:port]> <command> [options]"
	puts "command:"
	puts "   nodes                        show list of nodes"
	puts "   replset                      show list of replication sets"
	puts "   stat                         show status of nodes"
	puts "   items                        show stored number of items"
	puts "   remove_node <nid>            remove a node from the cluster"
	puts "   set_weight <rsid> <weight>   set distribution weight"
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

module TArray
	class Template < Array
		def initialize
			super()
		end
		def from_msgpack(obj)
			obj.each {|v|
				push self.class::CLASS.new.from_msgpack(v)
			}
			self
		end
	end
	def self.new(klass)
		Class.new(Template) do
			const_set(:CLASS, klass)
		end
	end
end

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

def get_node
	call(nil,'status','nodes').map {|nid,address,name,rsids|
		address = MessagePack::RPC::Address.load(address)
		[nid, address, name, rsids]
	}.sort_by {|nid,address,name,rsids|
		nid
	}
end

def get_node_map
	map = {}
	call(nil,'status','nodes').each {|nid,address,name,rsids|
		address = MessagePack::RPC::Address.load(address)
		map[nid] = [address, name, rsids]
	}
	map
end

def each_node(&block)
	result = []
	get_node.each {|nid,address,name,rsids|
		result << yield($net.get_session(address), nid, address, name, rsids)
	}
	result
end

case cmd
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

when 'nodes'
	cmd_args(0)

	fault_nids = call(nil,'status','fault')

	NODES_FORMAT = "%3s %15s %23s   %7s %10s"
	puts NODES_FORMAT % %w[nid name address replset state]

	get_node.each {|nid,address,name,rsids|
		rsids = rsids.sort.join(',')
		state = fault_nids.include?(nid) ? 'FAULT' : 'active'
		puts NODES_FORMAT % [nid, name, address, rsids, state]
	}

when 'remove_node'
	nid_s = cmd_args(1)
	nid = nid_s.to_i
	if nid.to_s != nid_s
		raise "invalid nid: #{nid}"
	end
	pp call(nil,'remove_node',nid)

when 'replset'
	cmd_args(0)
	REPLSET_FORMAT = "%7s %8s %10s  %s"
	puts REPLSET_FORMAT % %w[replset weight nids names,...]
	node_map = get_node_map
	call(nil,'status','replset').each {|rsid,(nids,weight)|
		names = nids.map {|nid| node_map[nid][1] }.join(',')
		nids = nids.sort.join(',')
		puts REPLSET_FORMAT % [rsid, weight, nids, names]
	}

when 'stat', 'status'
	STAT_FORMAT = "%4s %15s %10s %10s %10s %10s"
	puts STAT_FORMAT % %w[nid name uptime #get #set #remove]
	each_node {|s,nid,address,name,rsids|
		uptime     = s.call(:status, 'uptime')     rescue nil
		cmd_get    = s.call(:status, 'cmd_get')    rescue nil
		cmd_set    = s.call(:status, 'cmd_set')    rescue nil
		cmd_remove = s.call(:status, 'cmd_remove') rescue nil
		puts STAT_FORMAT % [nid, name, uptime, cmd_get, cmd_set, cmd_remove]
	}

when 'items'
	ITEMS_FORMAT = "%4s %15s %10s %10s"
	puts ITEMS_FORMAT % %w[nid name rsid #items]
	map = {}
	each_node {|s,nid,address,name,rsids|
		items = s.call(:status, 'db_items') rescue nil
		puts ITEMS_FORMAT % [nid, name, rsids.join(','), items]
		if items
			rsids.each {|rsid|
				if !map[rsid] || map[rsid] < items
					map[rsid] = items
				end
			}
		end
	}
	total = map.values.inject(0) {|r,n| r + n }
	puts "total: #{total}"

when 'pid'
	# all
	# FIXME

when 'version'
	# all
	# FIXME

else
	puts "unknown command #{cmd}"
	puts ""
	usage
end

