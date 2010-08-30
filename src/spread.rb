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

require 'rubygems'
require 'yaml'
require 'pp'
require 'msgpack/rpc'
require 'lib/cclog'
require 'lib/ebus'
require 'lib/log_storage'
require 'lib/nested_db'
require 'lib/seqid_generator'
require 'type/address'
require 'type/boot_info'
require 'type/nodes_info'
require 'type/fault_info'
require 'type/replset_info'
require 'type/node'
require 'type/heartbeat'
require 'service/base'
require 'service/boot_info'
require 'service/fault_info'
require 'service/heartbeat'
require 'service/nodes_info'
require 'service/replset_info'
require 'service/locator'
require 'service/term'
require 'service/recognize'
require 'service/master_storage'
require 'service/slave_storage'
require 'service/storage_index'
require 'service/storage'
require 'service/seqid_generator'
require 'service/object_index'
require 'service/index_client'
require 'service/routing'
require 'service/gateway'
require 'service/osd_role'
require 'service/mds_role'
require 'service/gateway_role'
require 'bus'
require 'rpc'

module SpreadOSD


$log = CCLog.new
$log.level = CCLog::LEVEL_DEBUG
#$log.level = CCLog::LEVEL_TRACE

$ebus = EventBus.default = EBus.new

$net = MessagePack::RPC::Server.new


end

