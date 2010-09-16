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
	def expired?
		@value <= 0
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
		expired_nids = []
		@map.each_pair {|nid,term|
			if term.value > 0
				term.value -= 1
				if term.value == 0
					expired_nids << nid
				end
			end
		}
		expired_nids

		expired_nids.each {|nid|
			$log.debug "fault detected: nid=#{nid}"
		}

		ebus_signal :node_fault_detected, expired_nids
	end

	def get_expired
		expired_nids = []
		@map.each_pair {|nid,term|
			if term.value <= 0
				expired_nids << nid
			end
		}
		expired_nids
	end

	#def node_list_changed(node_list)
	#	new_map = {}
	#	node_list.nodes.each {|node|
	#		next if node.nid == @self_nid
	#		term = @map[node.nid] || Term.new(@period+@first_detect)
	#		new_map[node.nid] = term
	#	}
	#	@map = new_map
	#end

	def fault_info_changed(fault_info)
		@map.each_pair {|nid,term|
			unless fault_info.include?(nid)
				term.value = @period+@detect
			end
		}
	end

	#def set_term_nids(nids, fault_info)
	#	@map.reject! {|nid,term|
	#		!nids.include?(nid)
	#	}
	#	nids.each {|nid|
	#		if term = @map[nid]
	#			if term.value <= 0 && !fault_info.include?(nid)
	#				# recovered
	#				term.value = @period+@first_detect
	#			end
	#		else
	#			@map[nid] = Term.new(@period+@first_detect)
	#		end
	#	}
	#end

	def term_nids_changed(nids)
		@map.reject! {|nid,term|
			!nids.include?(nid)
		}
		nids.each {|nid|
			next if nid == @self_nid
			@map[nid] ||= Term.new(@period+@first_detect)
		}
	end

	ebus_connect :on_timer
	ebus_connect :term_order, :order
	ebus_connect :term_reset, :reset
	ebus_connect :term_nids_changed
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

		expired_num = 0
		@map.each_pair {|qsid,term|
			if term.value <= 0
				expired_num += 1
			end
		}

		if expired_num > majority_border
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
			# FIXME shutdown?
			ebus_signal :shutdown
		end
	end

	# FIXME
	# on qsid_changed => update keys of @map

	ebus_connect :on_timer
	ebus_connect :term_feed, :feed
end


end

