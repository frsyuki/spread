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


class OIDGeneratorService < Service
	def initialize
		super()
		@seqdb = SeqidGenerator.new
		@self_nid = ebus_call(:self_nid)
	end

	def generate_next_oid
		seq = @seqdb.next_id(:oid)
		seq << 16 | @self_nid
	end

	def run
		path = ebus_call(:get_seqid_path)
		@seqdb.open(path)
	end

	def shutdown
		@seqdb.close
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :generate_next_oid
end


end

