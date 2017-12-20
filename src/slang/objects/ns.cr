require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NSes
  property current = NS.global
  property nses = Hash(String, NS).new

  delegate :[]?, :[], :[]=, to: @current

  def initialize
    nses[current.name] = current
  end

  def change_ns(new_name)
    prev = @current
    @current = nses[new_name]? || NS.new new_name
    @current.import(prev)
    nses[new_name] = @current
  end

  def to_s(io)
    io << "ns: "
    io << current.name
    io << '\n'
    nses.each do |name, ns|
      ns.describe(io)
    end
  end
end

class NS
  property defs = Hash(String, Slang::Object).new
  property imported = Hash(String, NS).new
  property name : String

  def self.global
    new "Global"
  end

  def initialize(@name)
    @imported[@name] = self
    @defs[@name] = self.as(Slang::Object)
  end

  def import(ns : NS)
    @imported[ns.name] = ns
  end

  def [](iden : Slang::Identifier)
    if mod = iden.mod
      name = iden.value
      if (proto = @defs[mod]?) && proto.is_a? Slang::Protocol
        return proto.get_method(name)
      elsif ns = @imported[mod]?
        return ns[name]
      else
        raise "Unknown namespace #{mod}"
      end
    else
      @defs[iden.value]? || raise "Unknown var #{iden}"
    end
  end

  def [](iden : Slang::Atom)
    self[iden.value]
  end

  def [](iden : String)
    @defs[iden]
  end

  def []?(iden : String)
    @defs[iden]?
  end

  def []?(iden : Slang::Identifier)
    if mod = iden.mod
      name = iden.value
      if (proto = @defs[mod]?) && proto.is_a? Slang::Protocol
        return proto.get_method(name)
      elsif ns = @imported[mod]?
        return ns[name]?
      else
        nil
      end
    else
      @defs[iden.value]?
    end
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
