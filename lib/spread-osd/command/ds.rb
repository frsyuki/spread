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
require 'digest/md5'
require 'digest/sha1'
require 'csv'
require 'tokyotyrant'
require 'spread-osd/lib/cclog'
require 'spread-osd/lib/ebus'
require 'spread-osd/lib/vbcode'
require 'spread-osd/logic/tsv_data'
require 'spread-osd/logic/weight'
require 'spread-osd/logic/fault_detector'
require 'spread-osd/logic/membership'
require 'spread-osd/logic/snapshot'
require 'spread-osd/logic/node'
require 'spread-osd/logic/okey'
require 'spread-osd/service/base'
require 'spread-osd/service/bus'
require 'spread-osd/service/process'
require 'spread-osd/service/rpc'
require 'spread-osd/service/rpc_gw'
require 'spread-osd/service/rpc_ds'
require 'spread-osd/service/stat'
require 'spread-osd/service/stat_gw'
require 'spread-osd/service/stat_ds'
require 'spread-osd/service/config'
require 'spread-osd/service/config_gw'
require 'spread-osd/service/config_ds'
require 'spread-osd/service/data_server'
require 'spread-osd/service/data_client'
require 'spread-osd/service/mds'
require 'spread-osd/service/mds_tt'
require 'spread-osd/service/gateway'
require 'spread-osd/service/gateway_ro'
require 'spread-osd/service/gw_http'
require 'spread-osd/service/heartbeat'
require 'spread-osd/service/membership'
require 'spread-osd/service/snapshot'
require 'spread-osd/service/rts'
require 'spread-osd/service/rts_file'
require 'spread-osd/service/rts_memory'
require 'spread-osd/service/slave'
require 'spread-osd/service/snapshot'
require 'spread-osd/service/storage'
require 'spread-osd/service/storage_dir'
require 'spread-osd/service/ulog'
require 'spread-osd/service/ulog_file'
require 'spread-osd/service/ulog_memory'
require 'spread-osd/default'
require 'spread-osd/version'
require 'spread-osd/log'
require 'optparse'

include SpreadOSD

conf = DSConfigService.init

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = nil
listen_port = nil

read_only_gw = false

op.on('-i', '--nid ID', Integer, "unieque node id") do |nid|
	conf.self_nid = nid
end

op.on('-n', '--name NAME', "node name") do |name|
	conf.self_name = name
end

op.on('-a', '--address ADDRESS', "listen address") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = DS_DEFAULT_PORT if port == 0
	conf.self_address = Address.new(host, port)
	listen_host = host
	listen_port = port
end

op.on('-g', '--rsid IDs', "replication set IDs") do |ids|
	conf.self_rsids = ids.split(',').map {|id| id.to_i }
end

op.on('-s', '--store PATH', "path to storage directory") do |path|
	conf.storage_path = path
end

op.on('-u', '--ulog PATH', "path to update log directory") do |path|
	conf.ulog_path = path
end

op.on('-r', '--rts PATH', "path to relay timestamp directory") do |path|
	conf.rts_path = path
end

op.on('-t', '--http', "http listen port") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
	else
		host = '0.0.0.0'
		port = addr.to_i
	end
	conf.http_gateway_address = Address.new(host, port)
end

op.on('-R', '--read-only', "read-only mode", TrueClass) do |b|
	read_only_gw = b
end

op.on('-S', '--snapshot SID', "read-only mode using the snapshot", Integer) do |i|
	read_only_gw = true
	conf.read_only_sid = i
end

op.on('-c', '--cs ADDRESS', "address of config server") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = CS_DEFAULT_PORT if port == 0
	conf.cs_address = Address.new(host, port)
end

op.on('--fault_store PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('--membership_store PATH', "path to membership status file") do |path|
	conf.membership_path = path
end

op.on('--snapshot_store PATH', "path to snapshot status file") do |path|
	conf.snapshot_path = path
end

op.on('-v', '--verbose', "show debug messages", TrueClass) do |b|
	$log.level = 1 if b
end

op.on('--trace', "show debug and trace messages", TrueClass) do |b|
	$log.level = 0 if b
end

op.on('--color-log', "force to enable color log", TrueClass) do |b|
	$log.enable_color
end


begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

	unless conf.self_nid
		raise "--nid option is required"
	end

	unless conf.self_name
		raise "--name option is required"
	end

	unless conf.self_address
		raise "--address option is required"
	end

	unless conf.self_rsids
		raise "--rsid option is required"
	end

	unless conf.cs_address
		raise "--cs option is required"
	end

	unless conf.storage_path
		raise "--storage option is required"
	end

	unless conf.ulog_path
		conf.ulog_path = conf.storage_path
		#raise "--ulog option is required"
	end

	unless conf.rts_path
		conf.rts_path = conf.storage_path
		#raise "--rts option is required"
	end

	unless conf.fault_path
		conf.fault_path = File.join(conf.storage_path, "fault")
	end

	unless conf.membership_path
		conf.membership_path = File.join(conf.storage_path, "membership")
	end

	unless conf.snapshot_path
		conf.snapshot_path = File.join(conf.storage_path, "snapshot")
	end

rescue
	usage $!.to_s
end


ProcessService.init
HeartbeatMemberService.init
MembershipMemberService.init
DataClientService.init
if read_only_gw
	ReadOnlyGatewayService.init
else
	GatewayService.init
end
if conf.http_gateway_address
	HTTPGatewayService.open!
end
SnapshotMemberService.init
StorageSelector.open!
UpdateLogSelector.open!
RelayTimeStampSelector.open!
SlaveService.init
DataServerService.init
DSStatService.init

MembershipMemberService.instance.register_self_blocking! rescue nil
HeartbeatMemberService.instance.heartbeat_blocking! rescue nil


log_event_bus

net = ProcessBus.serve_rpc(DSRPCService.instance)

ProcessBus.run

net.listen(listen_host, listen_port)

puts "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown

