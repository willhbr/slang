require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NS
  property defs = Hash(String, Slang::Object).new
  property name : String

  def initialize(@name)
  end

  def alias(ns : NS)
    aliased.push ns
  end

  def lookup(name : String, &block)
    @defs.fetch name do
      yield
    end
  end

  def [](iden)
    @defs[iden]
  end

  def []=(name : Slang::Identifier, value)
    @defs[name.simple!] = value
  end

  def []=(name, value)
    @defs[name] = value
  end

  def to_s(io)
    inspect io
  end

  def inspect(io)
    io << @name << '<'
    first = true
    @defs.each_key do |name|
      io << ' ' unless first
      first = false
      io << name
    end
    io << '>'
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
