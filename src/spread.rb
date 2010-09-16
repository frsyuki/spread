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
require 'json'
require 'digest/sha1'
require 'lib/cclog'
require 'lib/ebus'
require 'lib/log_storage'
require 'lib/log_storage_index'
require 'lib/nested_db'
require 'lib/seqid_generator'
require 'type/address'
require 'type/node_list'
require 'type/fault_info'
require 'type/replset_info'
require 'type/node'
require 'type/role_data'
require 'type/heartbeat'

require 'service/base'
require 'service/timer'
require 'service/heartbeat'
require 'service/locator'
require 'service/term'
require 'service/routing'

require 'service/mds_boot'
require 'service/membership'
require 'service/oid_generator'
require 'service/metadata'

require 'service/ds_boot'
require 'service/storage_index'
require 'service/master_storage'
require 'service/slave_storage'

require 'service/gw_boot'
require 'service/metadata_client'
require 'service/gateway'

require 'bus'
require 'rpc'

module SpreadOSD


$log = CCLog.new
#$log.level = CCLog::LEVEL_DEBUG
$log.level = CCLog::LEVEL_TRACE

$ebus = EventBus.default = EBus.new

$net = MessagePack::RPC::Server.new


end

