require "./func"

module Slang
  module Dispatchable
    
  end

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
    getter attr_names : Array(String)

    def initialize(@attr_names)
    end

    # This is the constructor, called like a function
    def call(values)
      attrs = Hash(String, Object).new
      @attr_names.each_with_index do |attr, idx|
        attrs[attr] = values[idx]
      end
      {Instance.new(self, Slang::Map.new(attrs)), nil}
    end

    def dispatch_method(protocol, func, args)
      implementation = implementations[protocol]
      implementation[func].call(args)
    end

    def to_s(io)
      io << (@name || "unnamed")
    end
  end

  class Protocol
    property name : String? = nil
    property methods : Array(String)

    def initialize(@methods)
    end

    def describe(io)
      io << name << methods
    end

    def to_s(io)
      io << @name
    end

    def get_method(func)
      if methods.includes? func
        Method.new self, func
      else 
        raise "#{@name} doesn't define #{func}"
      end
    end
  end

  class Method < Callable
    def initialize(@protocol : Protocol, @func : String)
    end
    def call(args)
      arg = args.first
      raise "Can't call on #{arg}" unless arg.responds_to? :send
      arg.send(@protocol, @func, args)
    end
  end

  module CrystalSendable
    def send(protocol, func, args)
      type.dispatch_method(protocol, func, args)
    end

    def type
      {{ (@type.stringify + "Type").id }}.instance
    end
  end
end
