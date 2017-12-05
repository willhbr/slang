module Slang
  abstract class Object
    abstract def to_s(io)

    abstract def truthy?

    def self.nil
      Empty.instance
    end
  end

  class List < Object
    property value : Array(Object)

    delegate each, each_slice, size, first, empty?, :[], :[]?, :[]=, to: @value

    def initialize(@value = [] of Object)
    end

    def <<(value : Object) : List
      @value << value
      self
    end

    def truthy?
      !@value.empty?
    end

    def to_s(io)
      io << '('
      body_to_s(io)
      io << ')'
    end

    def body_to_s(io)
      first = true
      @value.each do |value|
        io << ' ' unless first
        first = false
        value.to_s io
      end
    end

    def data
      @value[1..-1]
    end

    def self.quoted
      List.new([Identifier.new("quote")] of Object)
    end

    def self.unquoted
      List.new([Identifier.new("quote")] of Object)
    end

    def self.do(rest)
      arr = [Identifier.new("do")] of Object
      rest.each do |r|
        arr << r
      end
      List.new(arr)
    end
  end

  class Vector < List
    def to_s(io)
      io << '['
      body_to_s(io)
      io << ']'
    end
  end

  class Empty < Object
    def to_s(io)
      io << "nil"
    end

    def truthy?
      false
    end

    def self.instance
      @@instance ||= Empty.new
    end
  end

  class Map < Object
    property value : Hash(Object, Object)

    def initialize(@value = {} of Object => Object)
    end

    delegate :[], :[]=, :each, to: @value

    def truthy?
      @value.empty?
    end

    def to_s(io)
      io << '{'
      first = true
      @value.each do |key, value|
        io << ' ' unless first
        first = false
        key.to_s io
        io << ' '
        value.to_s io
      end
      io << '}'
    end
  end

  class Identifier < Object
    property value : String

    def initialize(@value)
    end

    def to_s(io)
      io << @value
    end

    def truthy?
      true
    end

    def run(bindings)
      bindings[@value]
    end
  end

  class Number < Object
    property value : Int32

    def initialize(@value)
    end

    def truthy?
      value != 0
    end

    def to_s(io)
      io << @value
    end
  end

  class Atom < Object
    property value : String

    def initialize(@value)
    end

    def truthy?
      true
    end

    def to_s(io)
      io << ':'
      io << @value
    end
  end

  class Str < Object
    property value : String

    def initialize(@value)
    end

    def truthy?
      @value != ""
    end

    def to_s(io)
      io << @value
    end
  end

  abstract class Boolean < Object
    def self.new(val)
      val ? TrueClass.instance : FalseClass.instance
    end
  end

  class TrueClass < Boolean
    def truthy?
      true
    end

    def to_s(io)
      io << "true"
    end

    def self.instance
      @@inst ||= TrueClass.new
    end
  end

  class FalseClass < Boolean
    def truthy?
      false
    end
    def to_s(io)
      io << "false"
    end
    def self.instance
      @@inst ||= FalseClass.new
    end
  end
end
