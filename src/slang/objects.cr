module Slang
  abstract class Object
    abstract def to_s(io)

    def run(bindings)
      self
    end

    def call(args : List)
      raise "cannot call non-function object #{self}"
    end

    abstract def truthy?

    def self.nil
      Empty.instance
    end
  end

  abstract class Fn < Object
    def to_s(io)
      io << "Function"
    end

    def truthy?
      true
    end

    abstract def call(args)
  end

  class CrystalFn < Fn
    def initialize(@name : String, &@block : List -> Object)
    end

    def to_s(io)
      io << @name
    end

    def truthy?
      true
    end

    def call(args : List)
      @block.call args
    end
  end

  class List < Object
    property value : Array(Object)

    delegate first, :[], :[]?, :[]=, to: @value

    def initialize(@value = [] of Object)
    end

    def <<(value : Object) : List
      @value << value
      self
    end

    def truthy?
      !@value.empty?
    end

    def run(bindings)
      func = @value.first?
      raise "No function to run in ()" unless func
      runnable = func.run(bindings)
      runnable.call(List.new(@value[1..-1]))
    end

    def to_s(io)
      io << '('
      first = true
      @value.each do |value|
        io << ' ' unless first
        first = false
        value.to_s io
      end
      io << ')'
    end

    def self.quoted
      List.new([Identifier.new("quote")] of Object)
    end

    def self.unquoted
      List.new([Identifier.new("quote")] of Object)
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

    delegate :[], :[]=, to: @value

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
