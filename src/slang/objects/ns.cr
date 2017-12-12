require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NSes
  property current = NS.global
  property nses = Hash(String, NS).new

  delegate :[], :[]?, :[]=, to: @current

  def initialize
    nses[current.name] = current
  end

  def change_ns(new_name)
    puts "Changing from #{@current} to #{new_name}"
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
    @defs[@name] = self
  end

  def import(ns : NS)
    @imported[ns.name] = ns
  end

  def [](iden : String)
    if var = @defs[iden]?
      return var
    end
    arr = iden.split('.')
    raise "Can only have Module.var" if arr.size != 2
    mod, name = arr
    if ns = @imported[mod]?
      return ns[name]
    else
      raise "Unknown namespace #{mod}"
    end
  end

  def []?(iden : String)
    if var = @defs[iden]?
      return var
    end
    arr = iden.split('.')
    return nil if arr.size != 2
    mod, name = arr
    if ns = @imported[mod]?
      return ns[name]?
    else
      nil
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
