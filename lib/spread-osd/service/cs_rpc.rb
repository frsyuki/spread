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


class CSRPCService < Service
	def initialize
		super
	end

	def heartbeat(nid=nil, sync_request)
		dispatch(:heartbeat, nid, sync_request)
	end

	def add_node(nid, address, name, rsids)
		address = Address.load(address)
		dispatch(:add_node, nid, address, name, rsids)
	end

	def remove_node(nid)
		dispatch(:remove_node, nid)
	end

	def update_node_info(nid, address, name, rsids)
		address = Address.load(address)
		dispatch(:update_node_info, nid, address, name, rsids)
	end

	def recover_node(nid)
		dispatch(:recover_node, nid)
	end

	def get_mds
		dispatch(:get_mds)
	end

	def set_replset_weight(rsid, weight)
		dispatch(:set_replset_weight, rsid, weight)
	end

	def status(cmd)
		dispatch(:status, cmd)
	end

	private
	def dispatch(name, *args)
		$log.trace { "rpc: #{name} #{args}" }
		ebus_call("rpc_#{name}".to_sym, *args)
	rescue => e
		msg = ["rpc error on #{name}: #{e}"]
		e.backtrace.each {|bt| msg <<  "    #{bt}" }
		$log.error msg.join("\n")
		raise
	end

	public
	def self.serve
		$net.serve(instance)
		$net
	end
end


end
