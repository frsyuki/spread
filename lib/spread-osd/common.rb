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
require 'spread-osd/lib/cclog'
require 'spread-osd/lib/ebus'
require 'spread-osd/lib/vbcode'
require 'spread-osd/logic/node'
require 'spread-osd/logic/weight'
require 'spread-osd/logic/fault_detector'
require 'spread-osd/logic/membership'
require 'spread-osd/logic/storage_manager'
require 'spread-osd/logic/master_storage_manager'
require 'spread-osd/logic/slave_storage_manager'
require 'spread-osd/service/base'
require 'spread-osd/service/net'
require 'spread-osd/service/storage'
require 'spread-osd/service/timer'
require 'spread-osd/service/config'
require 'spread-osd/service/status'
require 'spread-osd/service/heartbeat'
require 'spread-osd/service/membership'
require 'spread-osd/service/mds'
require 'spread-osd/service/gateway'
require 'spread-osd/service/storage_client'
require 'spread-osd/service/ds_config'
require 'spread-osd/service/ds_rpc'
require 'spread-osd/service/ds_status'
require 'spread-osd/service/cs_config'
require 'spread-osd/service/cs_rpc'
require 'spread-osd/service/cs_status'
require 'spread-osd/service/gw_config'
require 'spread-osd/service/gw_rpc'
require 'spread-osd/service/gw_status'
require 'spread-osd/storage/base'
require 'spread-osd/storage/file'
require 'spread-osd/storage/hash'
require 'spread-osd/mds/base'
require 'spread-osd/mds/tokyotyrant'
require 'spread-osd/mds/astt'
require 'spread-osd/ulog/base'
require 'spread-osd/ulog/array'
require 'spread-osd/ulog/file'
require 'spread-osd/rlog/base'
require 'spread-osd/rlog/file'
require 'spread-osd/rlog/memory'
require 'spread-osd/bus'
require 'spread-osd/default'

require 'spread-osd/version'


$log = CCLog.new
$log.level = CCLog::LEVEL_INFO
#$log.level = CCLog::LEVEL_TRACE

$ebus = EventBus.default = SpreadOSD::EBus.new

$net = MessagePack::RPC::Server.new


end
