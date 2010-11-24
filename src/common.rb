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
module SpreadOSD


require 'rubygems'
require 'yaml'
require 'pp'
require 'msgpack/rpc'
require 'json'
require 'csv'
require 'digest/sha1'
require 'lib/cclog'
require 'lib/ebus'
require 'lib/vbcode'
require 'logic/node'
require 'logic/weight'
require 'logic/fault_detector'
require 'logic/membership'
require 'logic/storage_manager'
require 'logic/master_storage_manager'
require 'logic/slave_storage_manager'
require 'service/base'
require 'service/net'
require 'service/storage'
require 'service/timer'
require 'service/config'
require 'service/status'
require 'service/heartbeat'
require 'service/membership'
require 'service/mds'
require 'service/gateway'
require 'service/storage_client'
require 'service/ds_config'
require 'service/ds_rpc'
require 'service/ds_status'
require 'service/cs_config'
require 'service/cs_rpc'
require 'service/cs_status'
require 'service/gw_config'
require 'service/gw_rpc'
require 'service/gw_status'
require 'storage/base'
require 'storage/file'
require 'storage/hash'
require 'mds/base'
require 'mds/tokyotyrant'
require 'ulog/base'
require 'ulog/array'
require 'ulog/file'
require 'rlog/base'
require 'rlog/file'
require 'rlog/memory'
require 'bus'
require 'default'


$log = CCLog.new
$log.level = CCLog::LEVEL_INFO
#$log.level = CCLog::LEVEL_TRACE

$ebus = EventBus.default = SpreadOSD::EBus.new

$net = MessagePack::RPC::Server.new


end
