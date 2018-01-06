require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NSes
  property current : NS
  property nses = Hash(String, NS).new

  def initialize
    @current = NS.new "Global"
    @nses[@current.name] = @current
  end

  def change_ns(new_name)
    prev = @current
    @current = nses[new_name]? || NS.new new_name
    # @current.import(prev)
    @nses[new_name] = @current
  end

  def alias_to(old, new_name)
    ns = @nses[old]
    @nses[new_name] = ns
  end

  def to_s(io)
    io << "ns: "
    io << current.name
    io << '\n'
    nses.each do |name, ns|
      ns.describe(io)
    end
  end

  def []?(iden : Slang::Identifier)
    if modul = iden.mod
      ns = @nses[modul]?
      return nil unless ns
      ns[iden.value]?
    else
      @current[iden.value]?
    end
  end

  def [](iden : Slang::Identifier)
    if modul = iden.mod
      ns = @nses.fetch modul do
        error! "Undefined module #{modul}"
      end
      trace(ns[iden.value], iden)
    else
      trace(@current[iden.value], iden)
    end
  end

  delegate :[]=, :[], to: @current
end

class NS
  property defs = Hash(String, Slang::Object).new
  property aliased = Array(NS).new
  property name : String

  def initialize(@name)
  end

  def alias(ns : NS)
    aliased.push ns
  end

  def [](iden : Slang::Atom)
    self[iden.value]
  end

  def [](iden : String)
    @defs.fetch iden do
      error! "Unbound def #{name}.#{iden}"
    end
  end

  def []?(iden : String)
    @defs[iden]?
  end

  def []=(name : Slang::Identifier, value)
    error! "Can't define within namespace", name if name.mod
    @defs[name.value] = value
  end

  def []=(name, value)
    @defs[name] = value
  end

  def to_s(io)
    io << @name
  end

  def describe(io)
    io << @name
    io << '\n'
    @defs.each do |n, d|
      io << n
      io << ": "
      d.to_s io
      io << '\n'
    end
  end
end
