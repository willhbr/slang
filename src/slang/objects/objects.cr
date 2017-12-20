require "immutable"

module Slang

  class Identifier
    property value : String
    property location : FileLocation

    def initialize(@location, @value)
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
      io << ':' << @value
    end

    def with_colon_suffix(io : IO)
      io << @value << ':'
    end

    def hash
      @value.hash
    end

    def call(args)
      first = args.first
      if first.responds_to? :[]
        {first[self], nil}
      else
        {nil, nil}
      end
    end
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | Atom | Identifier | Splice |
                  Function | Protocol | Callable | Instance | Regex | NSes | NS | Nil | Wrapper)

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
    property trace : Array(FileLocation)    

    def initialize(@message : String, cause : Identifier)
      @trace = [] of FileLocation
    end

    def to_s(io)
      io << @message
    end

    def add_to_trace(location : FileLocation)
      @trace.push location
    end

    def backtrace
      "#{@message}: #{@trace.join '\n'}"
    end
  end
end

class Protocols
  macro proto(name, methods)
    @@{{ name }} = Slang::Protocol.new({{ methods }})
    def self.{{ name }}
      @@{{ name }}.name ||= {{ name.stringify.capitalize }}
      @@{{ name }}
    end
  end

  macro finished
    ALL = [{% for proto in @type.class.methods %}
      {% if proto.name != "allocate" %}
        Protocols.{{ proto.name }},
      {% end %}
    {% end %}]
  end

  proto lengthable, ["length"]
  proto printable, ["->string"]
end
macro type(t, implement, use=:class)
  {% name = (t.stringify + "Type").id %}
  {% if use == :class %}
    class {{ t }}
      include Slang::CrystalSendable
    end
  {% else %}
    struct {{ t }}
      include Slang::CrystalSendable
    end
  {% end %}
  class {{ name }} < Slang::Type
    def initialize
      super [] of Slang::Atom
      @name = {{ t.stringify }}
      @implementations = {{ implement }}
    end

    def self.instance
      @@inst ||= {{ name }}.new
    end
  end
end

type Int32, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Int32).to_s
    }.as(Slang::Callable)
  }
}, use: :struct 

type Map, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      no_error! args.first.as(Slang::Map).size
    }.as(Slang::Callable)
  }
}
type Vector, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      no_error! args.first.as(Slang::Vector).size
    }.as(Slang::Callable)
  }
}
type String, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      no_error! args.first.as(String).size
    }.as(Slang::Callable)
  },
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(String).to_s
    }.as(Slang::Callable)
  }
}
type Bool, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Bool).to_s
    }.as(Slang::Callable)
  }
}, use: :struct 
type Atom, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Atom).to_s
    }.as(Slang::Callable)
  }
}, use: :struct 
type Identifier, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Identifier).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Splice, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Splice).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Function, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Function).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Callable, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Callable).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Instance, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Instance).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Regex, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Regex).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type NSes, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(NSes).to_s
    }.as(Slang::Callable)
  }
}, use: :class 
type Nil, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Nil).to_s
    }.as(Slang::Callable)
  }
}, use: :struct 
type Wrapper, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      no_error! args.first.as(Wrapper).to_s
    }.as(Slang::Callable)
  }
}, use: :struct 

class String
  def [](iden : Slang::Atom)
    nil
  end
end
