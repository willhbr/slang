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
      @type.to_s(io)
      io << ": "
      @attributes.to_s(io)
    end
  end

  class Type < Callable
    # property implementations = Hash(Protocol, ProtocolImplementation).new
    property methods = Hash(String, Function).new
    property name : String?
    getter attr_names : Array(String)

    def initialize(@attr_names)
    end

    def call(values)
      attrs = Hash(String, Object).new
      @attr_names.each_with_index do |attr, idx|
        attrs[attr] = values[idx]
      end
      {Instance.new(self, Slang::Map.new(attrs)), nil}
    end

    def to_s(io)
      io << (@name || "unnamed")
    end
  end
end
