#
# EventBus
# Copyright (c) 2010 FURUHASHI Sadayuki
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
require 'forwardable'
require 'singleton'

class EventBus
	def self.bus(&block)
		Class.new(Bus, &block)
	end

	class SlotError < NameError
	end

	class Slot
	end

	class CallSlot < Slot
		def initialize(bus, name)
			@bus = bus
			@name = name
			@method = nil
		end

		attr_reader :method
		attr_reader :name

		def connect(method=nil, &block)
			if @method
				raise ::EventBus::SlotError.new("slot already connected", @name)
			end
			method ||= block
			@method = method
			@bus
		end

		def disconnect!
			@method = nil
			@bus
		end

		def call(*args, &block)
			unless @method
				raise ::EventBus::SlotError.new("slot not connected", @name)
			end
			@bus.ebus_call_log(@method, args, &block)
			@method.call(*args, &block)
		end

		alias signal call

		def to_s
			m = @method.inspect[/\#\<[^\:]*\:\s?(.+)\>/, 1]
			unless m
				m = m.to_s
			end
			"#<slot :#{@name} => #{m}>"
		end
	end

	class SignalSlot < Slot
		def initialize(bus, name)
			@bus = bus
			@name = name
			@methods = []
		end

		attr_reader :methods
		attr_reader :name

		def connect(method=nil, &block)
			method ||= block
			unless @methods.include?(method)
				@methods << method
			end
			@bus
		end

		def disconnect!
			@methods.clear
			@bus
		end

		def call(*args, &block)
			@bus.ebus_signal_log(methods, args, &block)
			methods.each {|block|
				begin
					block.call(*args, &block)
				rescue => err
					@bus.ebus_signal_error(err)
				end
			}
			nil
		end

		alias signal call

		def to_s
			methods = @methods.map {|m|
				if s = m.inspect[/\#\<[^\:]*\:\s?(.+)\>/, 1]
					s
				else
					m.to_s
				end
			}
			"#<slot :#{@name} => [#{methods.join(',')}]>"
		end
	end

	def self.method2const(mname)
		mname = mname.to_s
		mname = mname.gsub(/\?$/,   '__p')
		mname = mname.gsub(/\!$/,   '__bang')
		mname = mname.gsub(/\=$/,   '__eq')
		mname = mname.gsub(/^\[\]/, '__at')
		mname
	end

	module DeclarerBase
		def call_slot(*slots)
			slots.each {|slot|
				slot = slot.to_sym
				s = CallSlot.new(self, slot)
				c = ::EventBus.method2const(slot)
				const = :"EBUS_SLOT_#{c}"
				ebus_def_slot_delegators(const, s)
			}
			self
		end

		def signal_slot(*slots)
			slots.each {|slot|
				slot = slot.to_sym
				s = SignalSlot.new(self, slot)
				c = ::EventBus.method2const(slot)
				const = :"EBUS_SLOT_#{c}"
				ebus_def_slot_delegators(const, s)
			}
			self
		end

		module Methods
			def connect(slot, method)
				slot = slot.to_sym
				__send__("connect_#{slot}", method)
			end

			def ebus_call_log(method, args, &block)
			end

			def ebus_signal_log(methods, args, &block)
			end

			def ebus_signal_error(err)
			end

			def ebus_all_slots
				slots = []
				(class<<self;self;end).module_eval do
					constants.each {|const|
						if const.to_s =~ /^EBUS_SLOT_.*/
							slots << const_get(const)
						end
					}
				end
				slots
			end

			def ebus_call_slots
				ebus_all_slots.select {|s|
					s.is_a?(CallSlot)
				}
			end

			def ebus_signal_slots
				ebus_all_slots.select {|s|
					s.is_a?(SignalSlot)
				}
			end
		end
	end

	module BusMixin
		include DeclarerBase
		include DeclarerBase::Methods
		include ::SingleForwardable

		def ebus_all_slots
			slots = []
			constants.each {|const|
				if const.to_s =~ /^EBUS_SLOT_.*/
					slots << const_get(const)
				end
			}
			slots
		end

		def ebus_disconnect!
			constants.each {|const|
				if const.to_s =~ /^EBUS_SLOT_.*/
					slot = const_get(const)
					slot.disconnect!
				end
			}
			nil
		end

		private
		def ebus_def_slot_delegators(const, s)
			const_set(const, s)
			def_delegator("self::#{const}", :call, s.name)
			def_delegator("self::#{const}", :connect, "connect_#{s.name}")
		end
	end

	class Bus
		extend BusMixin
	end


	module ObjectMixin
		include ::Forwardable

		include DeclarerBase

		def self.extended(mod)
			methods = DeclarerBase::Methods
			mod.instance_eval do
				include methods
			end
		end

		private
		def ebus_def_slot_delegators(const, s)
			const_set(const, s)
			def_delegator(const, :call, s.name)
			def_delegator(const, :connect, "connect_#{s.name}")
		end
	end

	class Object
		extend ObjectMixin
	end


	module SingletonMixin
		include BusMixin

		def self.extended(mod)
			mod.instance_eval do
				include ::Singleton
			end
		end

		class ConnectEntry
			def initialize(bus, slot, mname)
				@bus = bus
				@slot = slot
				@mname = mname
			end
			attr_reader :bus
			attr_reader :slot
			attr_reader :mname
		end

		def ebus_connect(bus, *slots)
			slots.each {|slot|
				case slot
				when Symbol
					ebus_connect_const_set(bus, slot, slot)
				when String
					ebus_connect_const_set(bus, slot.to_sym, slot.to_sym)
				when Hash
					slot.each_pair {|k,v|
						ebus_connect_const_set(bus, k.to_sym, v.to_sym)
					}
				else
					raise "slot name must be a Symbol: #{slot.inspect}"
				end
			}
		end

		alias connect ebus_connect

		def ebus_bind!
			constants.each {|const|
				if const.to_s =~ /^EBUS_CONNECT_.*/
					e = const_get(const)
					if e.bus.is_a?(Symbol)
						bus = eval("#{e.bus}")
					else
						bus = e.bus
					end
					bus.__send__("connect_#{e.slot}", instance.method(e.mname))
				end
			}
			self
		end

		alias bind! ebus_bind!

		private
		def ebus_connect_const_set(bus, slot, mname)
			e = ConnectEntry.new(bus, slot, mname)
			c = ::EventBus.method2const(slot)
			const_set(:"EBUS_CONNECT_#{c.object_id}_#{c}", e)
		end
	end

	class Singleton
		extend SingletonMixin
	end
end


if $0 == __FILE__
	def assert(boolean)
		unless boolean
			raise "test failed"
		end
	end

	def dump_slots(bus)
		if bus.is_a?(Class)
			puts bus.name
		else
			puts bus.class.name
		end
		bus.ebus_all_slots.each {|s|
			puts "  #{s}"
		}
	end

	module Test01
		Users = EventBus.bus do
			call_slot :add
			call_slot :get
			call_slot :added?
			signal_slot :user_added
		end

		class UserService < EventBus::Singleton
			def initialize
				@db = {}
			end

			def add(uid, name)
				@db[uid] = name
				Users.user_added(uid)
				name
			end

			def get(uid)
				@db[uid]
			end

			def added?(uid)
				@db.has_key?(uid)
			end

			connect Users, :add, :get, :added?
		end

		class UserCounter < EventBus::Singleton
			def initialize
				@count = 0
			end

			def on_add_user(uid)
				@count += 1
			end

			attr_reader :count

			connect Users, :user_added => :on_add_user

			call_slot :get_count
			connect self, :get_count => :count
		end

		UserService.bind!
		UserCounter.bind!

		dump_slots(Users)
		dump_slots(UserCounter)

		Users.add(0, "frsyuki")
		Users.add(1, "viver")
		assert Users.get(0) == "frsyuki"
		assert Users.get(1) == "viver"
		assert Users.added?(0) == true
		assert Users.added?(1) == true
		assert UserCounter.instance.count == 2
		assert UserCounter.get_count == 2
	end


	module Test02
		class Users < EventBus::Bus
			call_slot :add
			call_slot :get
			call_slot :added?
			signal_slot :user_added
		end

		class UserService
			extend EventBus::SingletonMixin

			def initialize
				@db = {}
			end

			def add(uid, name)
				@db[uid] = name
				Users.user_added(uid)
				name
			end

			def get(uid)
				@db[uid]
			end

			def added?(uid)
				@db.has_key?(uid)
			end

			connect Users, :add, :get, :added?
		end

		class UserCounter
			extend EventBus::BusMixin

			def initialize
				@count = 0
			end

			def on_add_user(uid)
				@count += 1
			end

			attr_reader :count
		end

		ucouter = UserCounter.new

		UserService.bind!
		Users.connect(:user_added, ucouter.method(:on_add_user))

		dump_slots(Users)

		Users.add(0, "frsyuki")
		Users.add(1, "viver")
		assert Users.get(0) == "frsyuki"
		assert Users.get(1) == "viver"
		assert Users.added?(0) == true
		assert Users.added?(1) == true
		assert ucouter.count == 2
	end


	module Test03
		class Button < EventBus::Object
			def press
				on_press
			end

			call_slot :on_press
		end

		class App
			def initialize
				@pressed = false
			end

			def draw
				a = Button.new
				a.connect(:on_press, method(:on_press))
				dump_slots(a)
				a
			end

			def on_press
				@pressed = true
			end

			attr_reader :pressed
		end

		app = App.new
		b = app.draw
		b.on_press

		assert app.pressed == true
	end


	module Test04
		class Button
			extend EventBus::ObjectMixin

			def press
				on_press
			end

			call_slot :on_press
		end

		class App
			def initialize
				@pressed = false
			end

			def draw
				a = Button.new
				a.connect(:on_press, method(:on_press))
				dump_slots(a)
				a
			end

			def on_press
				@pressed = true
			end

			attr_reader :pressed
		end

		app = App.new
		b = app.draw
		b.on_press

		assert app.pressed == true
	end
end

