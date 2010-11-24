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


class GatewayService < Service
	DATA_COLUMN = "data"

	def initialize
		super
		@sc = StorageClientService.instance
	end

	def rpc_get(key)
		ar = MessagePack::RPC::AsyncResult.new

		ebus_call(:mds_get, key) do |map|
			if rsid = map[DATA_COLUMN]
				rsid = rsid.to_i
				get_data(rsid, key) do |data|
					map[DATA_COLUMN] = data
					ar.result(map)
				end

			else
				ar.result(map)
			end

		end

		ar
	end

	def get_data(rsid, key, &block)
		@sc.get(rsid, key) do |data|
			block.call(data)
		end
	rescue
		# FIXME
		$log.warn $!
		block.call(nil)
	end

	def rpc_set(key, map)
		ar = MessagePack::RPC::AsyncResult.new

		data = map[DATA_COLUMN]

		ebus_call(:mds_get, key) do |current|
			rsid_s = current[DATA_COLUMN]

			if data
				if rsid_s
					rsid = rsid_s.to_i
				else
					rsid = ebus_call(:choice_rsid)
				end
				map[DATA_COLUMN] = rsid.to_s
				set_data_set_map(rsid, key, map, data) do |success|
					ar.result(success)
				end

			elsif rsid_s
				set_map_remove_data(rsid_s.to_i, key, map) do |success|
					ar.result(success)
				end

			else
				set_map(key, map) do |success|
					ar.result(success)
				end
			end
		end

		ar
	end

	def set_data_set_map(rsid, key, map, data, &block)
		@sc.set(rsid, key, data) do |success|
			if success
				begin
					ebus_call(:mds_set, key, map, &block)
				rescue
					# FIXME
					$log.warn $!
					block.call(false)
				end
			else
				block.call(false)
			end
		end
	rescue
		# FIXME
		$log.warn $!
		block.call(false)
	end

	def set_map_remove_data(rsid, key, map, &block)
		ebus_call(:mds_set, key, map) do |success|
			if success
				begin
					@sc.remove(rsid, key, &block)
				rescue
					# FIXME
					$log.warn $!
					block.call(false)
				end
			else
				block.call(false)
			end
		end
	rescue
		# FIXME
		$log.warn $!
		block.call(false)
	end

	def set_map(key, map, &block)
		ebus_call(:mds_set, key, map, &block)
	rescue
		# FIXME
		$log.warn $!
		block.call(false)
	end

=begin
	def rpc_set(key, map)
		ar = MessagePack::RPC::AsyncResult.new

		if data = map[DATA_COLUMN]
			#rsid = ebus_call(:choice_rsid)
			#rsid_s = rsid.to_s
			#map[DATA_COLUMN] = rsid_s
			#
			#modproc = Proc.new do |current|
			#	if rsid_current = current[DATA_COLUMN]
			#		rsid_s = map[DATA_COLUMN] = rsid_current
			#	end
			#	map
			#end
			#
			#ebus_call(:atomic, key, modproc) do |success|
			#	if success
			#		rsid = rsid_s.to_i
			#		set_data(rsid, key, map) do |success|
			#			ar.rescue(success)
			#		end
			#	else
			#		ar.result(false)
			#	end
			#end

			rsid = ebus_call(:choice_rsid)
			map[DATA_COLUMN] = rsid.to_s

			ebus_call(:mds_add_or_get, key, map) do |current|
				if current
					update_mds_set_data(rsid, key, map, current, data) do |success|
						ar.result(success)
					end

				else
					set_data(rsid, key, data) do |success|
						ar.result(success)
					end
				end
			end

		else
			# remove existent data?
			ebus_call(:mds_set, key, map) do |success|
				ar.result(success)
			end
		end

		ar
	end

	def update_mds_set_data(rsid, key, map, current, data, &block)
		if rsid_current = current[DATA_COLUMN]
			rsid_s = map[DATA_COLUMN] = rsid_current
			rsid = rsid_s.to_i
		end
		ebus_call(:mds_set, key, map) do |success|
			if success
				set_data(rsid, key, data, &block)
			else
				block.call(false)
			end
		end
	rescue
		# FIXME
		$log.warn $!
		block.call(false)
	end
=end

	def set_data(rsid, key, data, &block)
		@sc.set(rsid, key, data) do |success|
			block.call(success)
		end
	rescue
		# FIXME
		$log.warn $!
		block.call(false)
	end

	def rpc_remove(key)
		ar = MessagePack::RPC::AsyncResult.new

		ebus_call(:mds_remove, key) do |map|
			if rsid = map[DATA_COLUMN]
				rsid = rsid.to_i
				remove_data(rsid, key) do |success|
					ar.result(success)
				end

			else
				ar.result(true)
			end

		end

		ar
	end

	def remove_data(rsid, key, &block)
		@sc.remove(rsid, key) do |success|
			block.call(success)
		end
	rescue
		# FIXME
		block.call(false)
	end

	def rpc_get_direct(key, rsid)
		ar = MessagePack::RPC::AsyncResult.new

		get_data(rsid, key) do |data|
			ar.result(data)
		end

		ar
	end

	def rpc_set_direct(key, rsid, data)
		ar = MessagePack::RPC::AsyncResult.new

		set_data(rsid, key, data) do |success|
			ar.result(success)
		end

		ar
	end

	def rpc_remove_direct(key, rsid)
		ar = MessagePack::RPC::AsyncResult.new

		remove_data(rsid, key) do |success|
			ar.result(success)
		end

		ar
	end

	#def rpc_select(conds, columns, order, limit, skip)
	#end

	#def rpc_count(conds)
	#end

	ebus_connect :rpc_get
	ebus_connect :rpc_set
	ebus_connect :rpc_remove
	ebus_connect :rpc_get_direct
end


end
