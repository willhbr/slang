require "immutable"

module Slang

  class Identifier
    property value : String

    def initialize(@value)
    end

    def to_s(io)
      io << @value
    end
  end

  struct Atom
    property value : String

    def initialize(@value)
    end

    def to_s(io)
      io << ':'
      io << @value
    end
  end

  abstract class List
    def self.create(value, n=EmptyList.instance)
      Node.new(value, n)
    end

    def self.from(*vals : Object)
      tail = EmptyList.instance
      vals.reverse.each do |val|
        tail = List.create val, tail
      end
      tail
    end

    def self.from(vals : Array(Object))
      tail = EmptyList.instance
      vals.reverse.each do |val|
        tail = List.create val, tail
      end
      tail
    end

    def each(&block)
      current = self
      while current.is_a? Node
        yield current.value
        current = current.rest
      end
    end

    def each_but_last
      current = self
      return if current.is_a? EmptyList
      while (r = current.rest) && !r.is_a?(EmptyList)
        yield current.value
        current = r
      end
    end

    def last
      current = self
      raise "Can't last empty list" if current.is_a? EmptyList
      while !current.rest.is_a? EmptyList
        current = current.rest
      end
      current
    end

    def map(&block)
      return if empty?
      head = List.create(yield first)
      current = head
      rest.each do |item|
        value = yield item
        node = List.create(value)
        current.rest = node
        current = node
      end
      head
    end

    def map_to_arr(&block)
      res = [] of Object
      each do |item|
        res << yield item
      end
      res
    end

    abstract def to_s(io)

    abstract def [](idx)

    def self.quoted(rest)
      Node.new(Identifier.new("quote"), Node.new(rest))
    end

    def self.unquote_spliced(rest)
      Node.new(Identifier.new("unquote-splice"), Node.new(rest))
    end

    def self.unquoted(rest)
      Node.new(Identifier.new("unquote"), Node.new(rest))
    end

    def self.do(rest : Array(Object))
      tail = from(rest)
      create(Identifier.new("do"), tail)
    end
  end

  class Node < List
    property value : Object
    @rest : List = EmptyList.instance
    property rest

    def initialize(@value, @rest = EmptyList.instance)
    end

    def empty?
      false
    end

    def first
      @value
    end

    def data
      @rest
    end

    def [](idx)
      if idx == 0
        return @value
      else
        return @rest[idx - 1]
      end
    end

    def []?(idx)
      if idx == 0
        return @value
      else
        return @rest[idx - 1]?
      end
    end

    def from(idx)
      if idx == 0
        self
      else
        @rest.from(idx - 1)
      end
    end

    def to_s(io)
      current = self
      io << '('
      while current.is_a? Node
        io << ' ' unless current === self
        current.value.to_s io
        current = current.rest
      end
      io << ')'
    end
  end

  class EmptyList < List
    def self.instance
      @@inst ||= EmptyList.new
    end

    def to_s(io)
      io << "()"
    end

    def rest
      self
    end

    def empty?
      true
    end

    def first
      raise "Can't first an empty list"
    end

    def value
      raise "Can't get value from empty list"
    end

    def data
      self
    end
    
    def [](idx)
      raise "can't index empty list"
    end

    def []?(idx)
      nil
    end

    def from(_idx)
      self
    end
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | Atom | Identifier | Splice |
                  Function | CrystalFn | Nil | Wrapper)

  alias Vector = Immutable::Vector(Object)
  alias Map = Immutable::Map(Object, Object)

  class Immutable::Vector(T)
    def self.from(vals : Array(T))
      new vals
    end

    def each_but_last
      idx = 0
      stop_at = size - 2
      each_with_index do |item, idx|
        if idx == stop_at
          break
        end
        yield item
        idx += 1
      end
    end

    def to_s(io)
      io << '['
      first = true
      each do |item|
        io << ' ' unless first
        first = false
        item.to_s io
      end
      io << ']'
    end
  end

  class CrystalFn
    def initialize(@name : String, &@block : Array(Object) -> Result)
    end

    def to_s(io)
      io << @name
    end

    def call(args)
      @block.call args
    end
  end

  class Function
    property arg_names
    property splat_name
    property captured
    property body

    def initialize(@arg_names : Array(Identifier), @captured : Bindings,
                   @body : Slang::List, @splat_name : Identifier? = nil)
    end

    def to_s(io)
      io << '('
      io << {{ @type.stringify }}
      io << " ["
      first = true
      @arg_names.each do |arg|
        io << ' ' unless first
        first = false
        arg.to_s(io)
      end
      io << "] "
      @body.each do |arg|
        arg.to_s(io)
      end
      if @body.empty?
        io << "nil"
      end
      io << ')'
    end
  end

  class Macro < Function
  end
  alias Result = {Slang::Object, Slang::Error?}

  class Splice
    def initialize(@body : Object)
    end

    def into(outer)
      b = @body
      if b.is_a? Slang::List
        b.each do |elem|
          outer << elem
        end
      elsif b.is_a? Slang::Vector
        b.each do |elem|
          outer << elem
        end
      else
        outer << b
      end
    end
  end

  struct Wrapper
    property value : Bool | Nil

    def initialize(@value)
    end
  end

  class Error
    def initialize(@message : String, @index : Int32, @file : String)
    end

    def to_s(io)
      io << @message
    end
  end
end
