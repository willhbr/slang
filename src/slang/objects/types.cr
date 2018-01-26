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
macro type(t, implement, is_class=true)
  {% name = (t.stringify + "Type").id %}
  {% if is_class %}
    class {{ t }}
      include Slang::CrystalSendable
      deftype
    end
  {% else %}
    struct {{ t }}
      include Slang::CrystalSendable
      deftype
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
}, is_class: false

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
        acc = func.call([acc, Slang::Vector.new([k, v] of Slang::Object)] of Slang::Object, {} of String => Slang::Object)
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
        acc = func.call([acc, item] of Slang::Object, {} of String => Slang::Object)
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
}, is_class: false

module Slang
  type Atom, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Atom).to_s
      }.as(Slang::Callable)
    }
  }, is_class: false
  type Identifier, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Identifier).to_s
      }.as(Slang::Callable)
    }
  }, is_class: false
  type Splice, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Splice).to_s
      }.as(Slang::Callable)
    }
  }
  type Function, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Function).to_s
      }.as(Slang::Callable)
    }
  }
  # type Callable, {
  #   Protocols.printable => {
  #     "->string" => Slang::CrystalFn.new("->string") { |args|
  #       args.first.as(Callable).to_s
  #     }.as(Slang::Callable)
  #   }
  # }
  type Instance, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Instance).to_s
      }.as(Slang::Callable)
    }
  }
  type Regex, {
    Protocols.printable => {
      "->string" => Slang::CrystalFn.new("->string") { |args|
        args.first.as(Regex).to_s
      }.as(Slang::Callable)
    }
  }
end
type NSes, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(NSes).to_s
    }.as(Slang::Callable)
  }
}
type Nil, {
  Protocols.printable => {
    "->string" => Slang::CrystalFn.new("->string") { |args|
      args.first.as(Nil).to_s
    }.as(Slang::Callable)
  }
}, is_class: false

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
        acc = func.call([acc, item] of Slang::Object, {} of String => Slang::Object)
      end
      acc
    }.as(Slang::Callable)
  }
}
type NS, {
  Protocols.lengthable => {
    "length" => Slang::CrystalFn.new("length") { |args|
      args.first.as(NS).defs.size
    }.as(Slang::Callable)
  }
}

module Slang
  type Macro, {
    Protocols.lengthable => {
      "length" => Slang::CrystalFn.new("length") { |args|
        args.first.as(NS).defs.size
      }.as(Slang::Callable)
    }
  }

  type CrystalMacro, {
    Protocols.lengthable => {
      "length" => Slang::CrystalFn.new("length") { |args|
        args.first.as(NS).defs.size
      }.as(Slang::Callable)
    }
  }
  type CrystalFn, {
    Protocols.lengthable => {
      "length" => Slang::CrystalFn.new("length") { |args|
        args.first.as(NS).defs.size
      }.as(Slang::Callable)
    }
  }
  type Method, {
    Protocols.lengthable => {
      "length" => Slang::CrystalFn.new("length") { |args|
        args.first.as(NS).defs.size
      }.as(Slang::Callable)
    }
  }
  type Protocol, {
    Protocols.lengthable => {
      "length" => Slang::CrystalFn.new("length") { |args|
        args.first.as(NS).defs.size
      }.as(Slang::Callable)
    }
  }
end

class String
  def [](iden : Slang::Atom)
    nil
  end
end
