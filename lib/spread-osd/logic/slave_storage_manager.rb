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


class SlaveStorageManager
	class Replicator
		def initialize(storage, rlog_path)
			@rlog = RelayLog.open(rlog_path)
			@storage = storage
			@pulling = false
		end

		def close
			@rlog.close
		end

		def try_pull(nid, session, limit)
			if @pulling
				return nil
			end
			@pulling = true

			begin
				offset = @rlog.get_offset
				session.callback(:replicate_pull, offset, limit) do |future|
					ack_replicate_pull(nid, future)
				end

			rescue
				@pulling = false
				raise
			end
		end

		private
		def ack_replicate_pull(nid, future)
			next_offset, msgs = future.get

			return if msgs.empty?

			msgs.each {|key,data|
				apply(key, data)
			}

			@rlog.set_offset(next_offset)

		rescue
			# FIXME log
			$log.error "try pull from nid=#{nid}: #{$!}"
			raise
		ensure
			@pulling = false
		end

		def apply(key, data)
			if data
				@storage.set(key, data)
			else
				@storage.remove(key)
			end
		end
	end


	def initialize(manager)
		@manager = manager
		@repls = {}  # {nid => Replicator}
	end

	def open(rlog_path, storage)
		@rlog_path = rlog_path
		@storage = storage
	end

	def close
		@repls.each_pair {|nid, repl|
			repl.close
		}
	end

	def try_pull(nid, session)
		repl = open_replicator(nid)
		repl.try_pull(nid, session, PULL_LIMIT)
	end

	private
	PULL_LIMIT = 8*1024*1024  # 8MB

	def open_replicator(nid)
		if repl = @repls[nid]
			return repl
		end
		repl = Replicator.new(@storage, "#{@rlog_path}/rlog-#{nid}")
		@repls[nid] = repl
	end
end


end
