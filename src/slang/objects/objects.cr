require "immutable"

module Slang

  struct Identifier
    property mod : String?
    property value : String
    property location : FileLocation

    def initialize(@location, @value, @mod = nil)
    end

    def to_s(io)
      if m = mod
        io << mod << '.'
      end
      io << @value
    end

    def inspect(io)
      to_s(io)
    end

    def hash
      mod.hash ^ value.hash
    end
  end

  struct Atom
    property value : String

    delegate :hash, to: @value

    def initialize(@value)
    end

    def to_s(io)
      io << ':' << @value
    end

    def inspect(io)
      to_s io
    end

    def with_colon_suffix(io : IO)
      io << @value << ':'
    end

    def call(args, kw_args)
      first = args.first
      if first.responds_to? :[]
        first[self]
      else
        nil
      end
    end
  end

  struct KeywordArg
    property value : String

    delegate :hash, to: @value

    def initialize(@value)
    end

    def to_atom
      Atom.new(@value)
    end

    def to_s(io : IO)
      io << @value << ':'
    end
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | KeywordArg | Atom | Identifier | Splice |
                  Function | Protocol | Callable | Instance | Regex | NSes | NS | Nil)

  alias Result = Slang::Object

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

  class Error < Exception
    property trace : Array(Identifier | FileLocation)    

    def initialize(@message : String, cause)
      @trace = [cause] of Identifier | FileLocation
    end

    def to_s(io)
      backtrace io
    end

    def add_to_trace(location)
      @trace.push location
    end

    def backtrace(io)
      io << @message << " from: "
      first = true
      @trace.each do |location|
        io << '\n' unless first
        first = false
        if location.is_a? Identifier
          io << location.value << ' '
          location = location.location
        end
        location.to_s io
      end
    end
  end
end
