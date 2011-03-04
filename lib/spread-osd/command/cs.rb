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
require 'fileutils'
require 'spread-osd/lib/cclog'
require 'spread-osd/lib/ebus'
require 'spread-osd/lib/vbcode'
require 'spread-osd/logic/tsv_data'
require 'spread-osd/logic/weight'
require 'spread-osd/logic/fault_detector'
require 'spread-osd/logic/membership'
require 'spread-osd/logic/node'
require 'spread-osd/logic/okey'
require 'spread-osd/service/base'
require 'spread-osd/service/bus'
require 'spread-osd/service/process'
require 'spread-osd/service/rpc'
require 'spread-osd/service/rpc_cs'
require 'spread-osd/service/stat'
require 'spread-osd/service/stat_cs'
require 'spread-osd/service/config'
require 'spread-osd/service/config_cs'
require 'spread-osd/service/sync'
require 'spread-osd/service/heartbeat'
require 'spread-osd/service/membership'
require 'spread-osd/service/weight'
require 'spread-osd/service/balance'
require 'spread-osd/service/master_select'
require 'spread-osd/service/mds'
require 'spread-osd/service/mds_cache'
require 'spread-osd/service/log'
require 'spread-osd/default'
require 'spread-osd/version'
require 'optparse'

include SpreadOSD

conf = CSConfigService.init

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

store_path = nil

listen_host = '0.0.0.0'
listen_port = CS_DEFAULT_PORT

op.on('-p', '--port PORT', "listen port") do |addr|
	if addr.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = CS_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-l', '--listen HOST', "listen address") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
		port = CS_DEFAULT_PORT if port == 0
		listen_host = host
		listen_port = port
	else
		listen_host = addr
	end
end

op.on('-m', '--mds EXPR', "address of metadata server") do |s|
	conf.mds_uri = s
end

op.on('-M', '--mds-cache EXPR', "mds cache") do |s|
	conf.mds_cache_uri = s
end

op.on('-s', '--store PATH', "path to base directory") do |path|
	store_path = path
end

op.on('--fault_store PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('--membership_store PATH', "path to membership status file") do |path|
	conf.membership_path = path
end

op.on('--weight_store PATH', "path to weight status file") do |path|
	conf.weight_path = path
end

op.on('-o', '--log PATH') do |path|
	conf.log_path = path
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

	unless conf.mds_uri
		raise "--mds option is required"
	end

	if store_path
		FileUtils.mkdir_p(store_path)
	end

	if !conf.fault_path && store_path
		conf.fault_path = File.join(store_path, "fault")
	end

	if !conf.membership_path && store_path
		conf.membership_path = File.join(store_path, "membership")
	end

	if !conf.weight_path && store_path
		conf.weight_path = File.join(store_path, "weight")
	end

rescue
	usage $!.to_s
end


ProcessService.init
LogService.open!
SyncServerService.init
HeartbeatServerService.init
MembershipManagerService.init
WeightManagerService.init
MDSConfigService.init
MDSCacheConfigService.init
CSStatService.init

LogService.instance.log_event_bus

ProcessBus.run

net = ProcessBus.serve_rpc(CSRPCService.instance)
net.listen(listen_host, listen_port)

$log.info "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown

