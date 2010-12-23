#
#  EventBus
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


class EventBus
	module SignalDispatcher
		def ebus_dispatch_signal(methods, *args, &block)
			methods.each {|block|
				begin
					block.call(*args, &block)
				rescue => err
					ebus_signal_error(err)
				end
			}
		end

		protected
		def ebus_signal_error(err)
		end
	end

	include SignalDispatcher

	def initialize
		@slots = {}  # slot => [method]
	end

	def signal(slot, *args, &block)
		if methods = @slots[slot]
			ebus_dispatch_signal(methods, *args, &block)
		end
		nil
	end

	def call(slot, *args, &block)
		if methods = @slots[slot]
			methods.last.call(*args, &block)
		else
			raise "slot not connected"
		end
	end

	def connect(slot, method=nil &block)
		method ||= block
		if methods = @slots[slot]
			methods << method
		else
			@slots[slot] = [method]
		end
		self
	end

	@@default = EventBus.new

	def self.default
		@@default
	end

	def self.default=(ebus)
		@@default = ebus
	end

	module Connector
		def self.extended(mod)
			connected = Connected
			mod.instance_eval {
				include connected
			}
		end

		def ebus_connect(slot, method = slot)
			const_set("SLOT_#{slot}", method)
		end
	end

	module Connected
		def ebus_connect!(ebus = EventBus.default)
			self.class.constants.each {|const|
				sym = const.to_sym
				if slot_name = sym.to_s.gsub!(/SLOT_/,'')
					slot_name = slot_name.to_sym
					method_name = self.class.const_get(sym)
					ebus.connect(slot_name, method(method_name))
				end
			}
			instance_variable_set(:@ebus, ebus)
		end

		def ebus_signal(slot, *args, &block)
			@ebus.signal(slot, *args, &block)
		end

		def ebus_call(slot, *args, &block)
			@ebus.call(slot, *args, &block)
		end

		attr_reader :ebus
	end

	class Base
		extend Connector
		def initialize(ebus = EventBus.default)
			ebus_connect!(ebus)
		end
	end

	class Static
	end
end


class EventBus::Static
	include ::EventBus::SignalDispatcher

	def self.signal_slot(slot)
		varname = :"@#{slot}"
		# FIXME Ruby 1.8 *args
		define_method(slot) do |*args, &block|
			if methods = instance_variable_get(varname)
				ebus_dispatch_signal(methods, *args, &block)
			end
		end
		define_method("connect_#{slot}") do |method=nil, &block|
			method ||= block
			if methods = instance_variable_get(varname)
				methods << method
			else
				instance_variable_set(varname, [method])
			end
		end
	end

	def self.call_slot(slot)
		define_method("connect_#{slot}") do |method=nil, &block|
			method ||= block
			(class<<self;self;end).module_eval do
				if method.is_a?(Method)
					define_method(slot) do |*args, &block|
						method.call(*args, &block)
					end
				else
					define_method(slot, method)
				end
			end
			self
		end
	end

	def connect(slot, method=nil, &block)
		method ||= block
		send("connect_#{slot}", method)
	end

	def signal(slot, *args, &block)
		send(slot, *args, &block)
	end

	def call(slot, *args, &block)
		send(slot, *args, &block)
	end
end


if $0 == __FILE__
	class MyService
		extend EventBus::Connector

		def initialize(ebus)
			ebus_connect!(ebus)
		end

		def on_heartbeat(arg)
			puts "on_heartbeat: #{arg}"
		end

		def status(arg)
			"ok: #{arg}"
		end

		ebus_connect :heartbeat, :on_heartbeat
		ebus_connect :status

		def doit
			ebus_signal(:heartbeat, "signal-1")
			ebus_call(:status, "call-1")
		end
	end

	class EB < EventBus::Static
		signal_slot :heartbeat
		call_slot :status

		def ebus_signal_error(err)
			p err
		end
	end

	[EventBus, EB].each {|klass|
		ebus = klass.new

		str = MyService.new(ebus)
		str.doit

		ebus.signal(:heartbeat, "signal-2")
		puts ebus.call(:status, "call-2")
		ebus.signal(:heartbeat)  # error
	}
end

