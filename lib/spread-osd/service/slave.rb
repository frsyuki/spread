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


class SlaveBus < Bus
	call_slot :open
	call_slot :close
	call_slot :try_replicate
end


class SlaveService < Service
	class Replicator
		def initialize(storage, nid, rts)
			@storage = storage
			@nid = nid
			@rts = rts
			@pulling = false
		end

		def close
			@rts.close
		end

		def try_replicate(session, limit)
			if @pulling
				return nil
			end
			@pulling = true

			begin
				pos = @rts.get
				session.callback(:replicate_pull, pos, limit) do |future|
					ack_replicate_pull(future)
				end

			rescue
				$log.error "try replicate #{$!}"
				$log.debug_backtrace $!.backtrace
				@pulling = false
				raise
			end
		end

		private
		def ack_replicate_pull(future)
			npos, msgs = future.get

			return if msgs.empty?

			msgs.each {|vtime,key,offset,data|
				apply(vtime, key, offset, data)
			}

			@rts.set(npos)

		rescue
			# FIXME log
			$log.error "try pull from nid=#{@nid}: #{$!}"
			$log.debug_backtrace $!.backtrace
			raise
		ensure
			@pulling = false
		end

		def apply(vtime, key, offset, data)
			if data
				if offset
					@storage.write(vtime, key, offset, data)
				else
					@storage.set(vtime, key, data)
				end
			else
				@storage.remove(vtime, key)
			end
		end
	end

	def initialize
		@repls = {}  # {nid => Replicator}
	end

	def open
	end

	def close
		@repls.each_pair {|nid, repl|
			repl.close
		}
	end

	def try_replicate(nid, session)
		repl = open_replicator(nid)
		repl.try_replicate(session, PULL_LIMIT)
	end

	ebus_connect :SlaveBus,
		:open,
		:close,
		:try_replicate

	private
	PULL_LIMIT = 32*1024*1024  # 32MB

	def open_replicator(nid)
		if repl = @repls[nid]
			return repl
		end
		rts = RelayTimeStampBus.open(nid)
		repl = Replicator.new(StorageBus, nid, rts)
		@repls[nid] = repl
	end
end


end
