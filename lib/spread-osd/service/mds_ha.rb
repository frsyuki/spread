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


# single node:
#   host1:port1
#
# master-slave:
#   host1:port1,host2:port2
#
# master-slave with read weight:
#   host1:port1,host2:port2;0,1
#
# dual-master:
#   host1:port1--host2:port2
#
class BasicHADB
	DEFAULT_WEIGHT = 10

	def initialize(expr)
		@dbmap = {}    # {Address => DB}
		@writers = []   # [Address]
		@readers = []   # [Address]
		@readers_rr = 0

		expr.split('--').each {|line|
			nodes, weights = line.strip.split(';',2)

			addrs = nodes.strip.split(',').map {|node|
				host, port = node.split(':',2)
				port ||= DEFAULT_PORT
				port = port.to_i
				host.strip!
				Address.new(host, port)
			}

			weights = (weights||"").strip.split(',').map {|x| x.to_i }

			@writers << addrs.first

			addrs.each_with_index {|addr,i|
				weight = weights[i] ||= DEFAULT_WEIGHT
				weight.times {
					@readers << addr
				}
				@dbmap[addr] = nil
			}

			$log.info "MDS -- #{addrs.join(',')};#{weights.join(',')}"
		}

		if @dbmap.empty?
			raise "empty expression"
		end

		if @dbmap.size == 1
			# single node
			@readers = [@readers[0]]
		else
			@readers = @readers.sort_by {|addr| rand }
		end

		# open remote database
		@dbmap.keys.each {|addr|
			@dbmap[addr] = open_db(addr)
		}

	rescue
		@dbmap.each_pair {|addr,db|
			if db
				close_db(db) rescue nil
			end
		}
		raise "MDS: invlaid address expression: #{$!}"
	end

	def write(shard_key, &block)
		if @writers.size == 1
			n = 0
		else
			n = hash_key(shard_key) % @writers.size
		end
		ha_call(@writers, n) {|db|
			block.call(db)
		}
	end

	def read(shard_key, &block)
		@readers_rr += 1
		@readers_rr = 0 if @readers_rr >= @readers.size
		ha_call(@readers, @readers_rr) {|db|
			block.call(db)
		}
	end

	def close
		@dbmap.each_pair {|addr,db|
			close_db(db) rescue nil
		}
	end

	protected
	def open_db(addr)
		raise "LOGIC ERROR: not implemented!"
	end

	def ensure_db(db, addr)
		true
	end

	def error_result?(db, result)
		nil
	end

	def close_db(db)
		db.close
	end

	def hash_key(key)
		digest = Digest::MD5.digest(key)
		digest.unpack('C')[0]
	end

	def ha_call(array, idx, &block)
		db = nil
		failed = []
		sz = array.size
		sz.times {
			addr = array[idx % sz]
			unless failed.include?(addr)
				db = @dbmap[addr]
				if ensure_db(db, addr)
					@dbmap[addr] = db  # FIXME
					begin
						result = block.call(db)
						if err = error_result?(db, result)
							failed << [addr, err]
						else
							return result
						end
					rescue
						failed << [addr, $!]
					end
				end
			end
			idx += 1
		}
		raise "MDS error: #{failed.inspect}"  # TODO error message
	end
end


end
