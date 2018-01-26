require "./func"
require "./ns"

module Slang
  class Instance
    property type : Type
    property attributes : Slang::Map

    def initialize(@type, @attributes)
    end
    
    def set_attr(k, v)
      new(type, @attributes.set(k, v))
    end

    def to_s(io)
      io << '#'
      @type.to_s io
      @attributes.to_s(io)
    end
  end

  alias ProtocolImplementation = Hash(String, Callable)

  class Type < Callable
    property implementations = Hash(Protocol, ProtocolImplementation).new
    property name : String?
    getter attr_names : Array(Atom)

    def send(protocol, func, args, kw_args)
      type.dispatch_method(protocol, func, args, kw_args)
    end

    def type
      return self
    end

    def initialize(@attr_names)
    end

    # This is the constructor, called like a function
    def call(values, kw_args)
      first = values.first
      if first.is_a? Slang::Map
        Instance.new(self, first)
      else
        attrs = Hash(Atom, Object).new
        @attr_names.each_with_index do |attr, idx|
          attrs[attr] = values[idx]
        end
        Instance.new(self, Slang::Map.new(attrs))
      end
    end

    def dispatch_method(protocol, func, args, kw_args)
      implementation = implementations[protocol]? || raise "#{@name} doesn't implement #{protocol.name}"
      implementation[func].call(args, kw_args)
    end

    def to_s(io)
      io << (@name || "unnamed")
    end
  end

  class Protocol < NS
    property methods : Set(String)

    def initialize(@methods)
      super ""
    end

    def to_s(io)
      io << @name << '<'
      first = true
      methods.each do |meth|
        io << ' ' unless first
        first = false
        io << meth
      end
      io << '>'
    end

    def lookup(var : String, &block)
      if methods.includes? var
        Method.new self, var
      else
        super var do
          yield
        end
      end
    end

    def get_method(func)
      if methods.includes? func
        Method.new self, func
      else 
        error! "#{@name} doesn't define #{func}"
      end
    end
  end

  class Method < Callable
    def initialize(@protocol : Protocol, @func : String)
    end

    def call(args, kw_args)
      arg = args.first
      raise "Can't call on #{arg}" unless arg.responds_to? :send
      arg.send(@protocol, @func, args, kw_args)
    end

    def to_s(io)
      io << @func
    end

    def inspect(io)
      to_s io
    end
  end

  module CrystalSendable
    macro deftype(type = nil)
      def self.type
        {% if type == nil %}
          {{ (@type.stringify + "Type").id }}.instance
        {% else %}
          {{ type }}.instance
        {% end %}
      end
      def send(protocol, func, args, kw_args)
        type.dispatch_method(protocol, func, args, kw_args)
      end

      def type
        self.class.type
      end
    end
  end
end
