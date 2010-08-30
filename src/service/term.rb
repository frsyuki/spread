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


class Term
	def initialize(value)
		@value = value
	end
	attr_accessor :value
end


# DS: period秒で障害検出
# QS: period+detect秒で障害検出
# QS: 最初のorderを受け取る前はperiod+first_detectで検出

class TermFeederService < Service
	def initialize
		super()
		@period = 10
		@detect = 5
		@first_detect = 600
		@map = {}
		@self_nid = ebus_call(:self_nid)
	end

	attr_accessor :period
	attr_accessor :detect
	attr_accessor :first_detect

	def order(nid)
		term = @map[nid]
		if term && term.value > 0
			term.value = @period+@detect
			return @period
		end
		return nil
	end

	def reset(nid)
		if term = @map[nid]
			term.value = @period+@detect
		end
	end

	def on_timer
		expired = []
		@map.each_pair {|nid,term|
			if term.value > 0
				term.value -= 1
				if term.value == 0
					expired << nid
				end
			end
		}
		expired

		expired.each {|nid|
			$log.debug "fault detected: nid=#{nid}"
		}

		ebus_signal :fault_nodes_detected, expired
	end

	def get_expired
		expired = []
		@map.each_pair {|nid,term|
			if term.value <= 0
				expired << nid
			end
		}
		expired
	end

	def nodes_info_changed(nodes_info)
		new_map = {}
		nodes_info.nodes.each {|node|
			next if node.nid == @self_nid
			term = @map[node.nid] || Term.new(@period+@first_detect)
			new_map[node.nid] = term
		}
		@map = new_map
	end

	def fault_info_changed(fault_info)
		@map.each_pair {|nid,term|
			unless fault_info.include?(nid)
				term.value = @period+@detect
			end
		}
	end

	ebus_connect :timer_clock, :on_timer
	ebus_connect :term_order, :order
	ebus_connect :term_reset, :reset
	ebus_connect :nodes_info_changed
	ebus_connect :fault_info_changed
end


class TermEaterService < Service
	def initialize
		super()
		@map = {0 => Term.new(0)}  # FIXME qsid
	end

	def feed(qsid, period)
		term = @map[qsid]
		if term
			term.value = period
		end
	end

	def expired?(majority_border = nil)
		return false if @map.empty?

		majority_border ||= @map.size/2  # /2切り捨て

		expired = 0
		@map.each_pair {|qsid,term|
			if term.value <= 0
				expired += 1
			end
		}

		if expired > majority_border
			return true  # expired
		else
			return false
		end
	end

	def on_timer
		return if @map.empty?

		# edge trigger
		return if expired?

		@map.each_pair {|qsid,term|
			if term.value > 0
				term.value -= 1
			end
		}

		if expired?
			$log.error "fault detected"
			ebus_signal :fault_detected
		end
	end

	# FIXME
	# on qsid_changed => update keys of @map

	ebus_connect :timer_clock, :on_timer
	ebus_connect :term_feed, :feed
end


end

