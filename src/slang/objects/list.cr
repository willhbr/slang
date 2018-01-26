require "./types"

module Slang
  class List
    include Slang::CrystalSendable
    def type
      ListType.instance
    end
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

    def first_or_nil?
      if h = @head
        h.value
      else
        nil
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
      return self unless current
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

    def [](iden : Slang::Atom)
      nil
    end

    def [](idx : Int32)
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

    def conjed(item)
      List.new Node.new(item, @head)
    end

    def size
      current = @head
      s = 0
      while current
        s += 1
        current = current.rest
      end
      s
    end

    {% for size in [2, 3, 4] %}
      def splat_first_{{ size }}
        current = @head
        {
          {% for i in 0..size %}
            if c = current
              val = c.value
              current = c.rest
              val
            else
              nil
            end,
          {% end %}
        }
      end
    {% end %}

    {% for method in [:to_s, :inspect] %}
      def {{ method.id }}(io)
        current = @head
        io << '('
        while current
          io << ' ' unless current === @head
          current.value.{{ method.id }} io
          current = current.rest
        end
        io << ')'
      end
    {% end %}

    def self.quoted(location, rest)
      create(Identifier.new(location, "quote"), rest)
    end
    def self.derefed(location, rest)
      create(Identifier.new(location, "deref"), rest)
    end
    def self.unquote_spliced(location, rest)
      create(Identifier.new(location, "unquote-splice"), rest)
    end
    def self.unquoted(location, rest)
      create(Identifier.new(location, "unquote"), rest)
    end
    def self.do(location, rest : Array(Object))
      tail = from(rest)
      create(Identifier.new(location, "do"), tail)
    end
  end

  class Node
    property value : Object
    property rest : Node?

    def initialize(@value, @rest = nil)
    end
  end
end
