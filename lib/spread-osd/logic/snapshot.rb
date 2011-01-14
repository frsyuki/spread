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


class Snapshot
	def initialize(sid=nil, name=nil, time=nil)
		@sid = sid
		@name = name
		@time = time || Time.now.utc.to_i
	end

	attr_reader :sid
	attr_reader :name
	attr_reader :time

	def to_msgpack(out = '')
		[@sid, @name, @time].to_msgpack(out)
	end

	def from_msgpack(obj)
		@sid = obj[0]
		@name = obj[1]
		@time = obj[2]
		self
	end
end


class SnapshotList < TSVData
	FIRST_SNAPSHOT_NAME = "default"

	def initialize
		@list = [Snapshot.new(0,FIRST_SNAPSHOT_NAME)]
		super()
	end

	def add(name)
		sid = @list.last.sid + 1
		ss = Snapshot.new(sid, name)
		@list << ss
		on_change
		ss
	end

	def get_list
		@list.dup
	end

	def last_sid
		@list.last.sid
	end

	def to_msgpack(out = '')
		@list.to_msgpack(out)
	end

	def from_msgpack(msg)
		@list = msg.map {|obj|
			Snapshot.new.from_msgpack(obj)
		}
		on_change
		self
	end

	protected
	def read
		return unless @path

		begin
			list = []

			tsv_read do |row|
				sid = row[0].to_i
				name = row[1] || ""
				time = row[2] || 0

				list[sid] = Snapshot.new(sid, name, time)
			end

			if list.empty? || list[0].sid != 0
				list.unshift Snapshot.new(0,FIRST_SNAPSHOT_NAME)
			end

			@list = list
		rescue
			$log.debug $!
		end

		update_hash

	rescue
		$log.debug $!
		raise
	end

	def write
		return unless @path

		list = []
		tsv_write do |writer|
			@list.each {|ss|
				row = []
				row[0] = ss.sid.to_s
				row[1] = ss.name
				writer << row
			}
		end

	rescue
		$log.error $!
		raise
	end
end


end
