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
  proto enumerable, ["reduce"]
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
      args.first.as(Int32).to_s
    }.as(Slang::Callable)
  }
}, use: :struct

type Map, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      args.first.as(Slang::Map).size
    }.as(Slang::Callable)
  },
  Protocols.enumerable => {
    "reduce" => Slang::CrystalFn.new("reduce") { |args|
      map = args[0].as(Slang::Map)
      acc = args[1]
      func = args[2].as(Slang::Callable)
      err = nil
      map.each do |k, v|
        acc = func.call([acc, Slang::Vector.new([k, v] of Slang::Object)] of Slang::Object)
      end
      acc
    }.as(Slang::Callable)
  }
}
type Vector, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      args.first.as(Slang::Vector).size
    }.as(Slang::Callable)
  },
  Protocols.enumerable => {
    "reduce" => Slang::CrystalFn.new("reduce") { |args|
      vec = args[0].as(Slang::Vector)
      acc = args[1]
      func = args[2].as(Slang::Callable)
      err = nil
      vec.each do |item|
        acc = func.call([acc, item] of Slang::Object)
      end
      acc
    }.as(Slang::Callable)
  }
}
type String, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      args.first.as(String).size
    }.as(Slang::Callable)
  },
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(String).to_s
    }.as(Slang::Callable)
  }
}
type Bool, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Bool).to_s
    }.as(Slang::Callable)
  }
}, use: :struct
type Atom, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Atom).to_s
    }.as(Slang::Callable)
  }
}, use: :struct
type Identifier, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Identifier).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Splice, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Splice).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Function, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Function).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Callable, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Callable).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Instance, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Instance).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Regex, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Regex).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type NSes, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(NSes).to_s
    }.as(Slang::Callable)
  }
}, use: :class
type Nil, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Nil).to_s
    }.as(Slang::Callable)
  }
}, use: :struct
type Wrapper, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Wrapper).to_s
    }.as(Slang::Callable)
  }
}, use: :struct

type List, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      args.first.as(Slang::List).size
    }.as(Slang::Callable)
  },
  Protocols.enumerable => {
    "reduce" => Slang::CrystalFn.new("reduce") { |args|
      list = args[0].as(Slang::List)
      acc = args[1]
      func = args[2].as(Slang::Callable)
      err = nil
      list.each do |item|
        acc = func.call([acc, item] of Slang::Object)
      end
      acc
    }.as(Slang::Callable)
  }
}

class String
  def [](iden : Slang::Atom)
    nil
  end
end
