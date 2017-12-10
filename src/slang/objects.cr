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

  class List
    property head : Node? = nil

    def initialize(eachable)
      return if eachable.empty?
      current = Node.new eachable.first
      @head = current
      first = true
      eachable.each do |item|
        if first
          first = false
          next
        end
        node = Node.new item
        current.rest = node
        current = node
      end
    end

    def self.from(eachable)
      new eachable
    end

    def self.create(*eachable)
      new eachable
    end

    def initialize
    end

    def initialize(node : Node?)
      @head = node
    end

    def self.create(value)
      n = Node.new(value)
      List.new n
    end

    def empty?
      @head.nil?
    end

    def first
      if h = @head
        h.value
      else
        raise "Can't first empty list"
      end
    end

    def data
      if h = @head
        List.new h.rest
      else
        List.new
      end
    end

    def each(&block)
      current = @head
      while current
        yield current.value
        current = current.rest
      end
    end

    def rest
      if h = @head
        List.new h.rest
      else
        List.new
      end
    end

    def each_return_last(&block)
      result = nil
      current = @head
      while current
        result = yield current.value
        current = current.rest
      end
      result
    end

    def map(&block)
      current = @head
      return unless current
      head = Node.new yield current.value
      prev = head
      current = current.rest
      while current
        n = Node.new yield current.value
        prev.rest = n
        prev = n
        current = current.rest
      end
      List.new head
    end

    def map_to_arr(&block)
      res = [] of Object
      each do |item|
        res << yield item
      end
      res
    end

    def []?(idx)
      current = @head
      while current
        if idx == 0
          return current.value
        end
        idx -= 1
        current = current.rest
      end
      nil
    end

    def [](idx)
      current = @head
      while current
        if idx == 0
          return current.value
        end
        idx -= 1
        current = current.rest
      end
      raise "Index out of range"
    end

    def from(idx)
      current = @head
      while current
        if idx == 0
          return List.new current
        end
        idx -= 1
        current = current.rest
      end
      List.new
    end

    def to_s(io)
      current = @head
      io << '('
      while current
        io << ' ' unless current === @head
        current.value.to_s io
        current = current.rest
      end
      io << ')'
    end

    def self.quoted(rest)
      create(Identifier.new("quote"), rest)
    end
    def self.unquote_spliced(rest)
      create(Identifier.new("unquote-splice"), rest)
    end
    def self.unquoted(rest)
      create(Identifier.new("unquote"), rest)
    end
    def self.do(rest : Array(Object))
      tail = from(rest)
      create(Identifier.new("do"), tail)
    end
  end

  class Node
    property value : Object
    property rest : Node?

    def initialize(@value, @rest = nil)
    end
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | Atom | Identifier | Splice |
                  Function | CrystalFn | Regex | Nil | Wrapper)

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
