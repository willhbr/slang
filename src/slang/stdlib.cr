require "./objects"
require "../slang"

macro func(bind, name, type=Slang::CrystalFn, &body)
  {% if name.is_a? SymbolLiteral %}
    name = {{ name }}.to_s
  {% else %}
    name = {{ name.stringify }}
  {% end %}
  {{bind}} = {{bind}}.set(name, ({{ type }}.new(name) {{ body }}))
end

class Lib::Runtime
  def self.new
    bind = Bindings.new

    ns = NSes.new

    Protocols::ALL.each do |proto|
      ns[proto.name.as(String)] = proto
    end
    
    bind = bind.set "*ns*", ns.as(Slang::Object)

    func(bind, println) do |args|
      puts args.join(" ")
      no_error! nil
    end

    func(bind, conj) do |args|
      first = args.first
      if first.is_a? Slang::List
        no_error! first.conjed(args[1])
      # elsif first.is_a? Slang::Vector
      #   vec = first.push(args[1].as(Slang::Object))
      #   no_error! vec
      else
        error! "can't add to #{first}"
      end
    end


    func(bind, first) do |args|
      a = args[0]
      next error! "Can't get first of non-list" unless a.is_a? Slang::List
      next no_error!(nil) if a.empty?
      no_error! a.first
    end

    func(bind, rest) do |args|
      a = args[0]
      next error! "Can't get rest of non-list" unless a.is_a? Slang::List
      next no_error!(a) if a.empty?
      no_error! a.data
    end

    func(bind, :<=) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        no_error! a <= b
      elsif a.is_a?(String) && b.is_a?(String)
        no_error! a <= b
      else
        next error! "Can't compare that business"
      end
    end

    func(bind, :+) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        no_error! a + b
      elsif a.is_a?(String) && b.is_a?(String)
        no_error! a + b
      else
       next error! "Can't add that business"
      end
    end

    func(bind, :-) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        no_error! a - b
      else
        next error! "Can't subtract that business"
      end
    end

    func(bind, :*) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        no_error! a * b
      else
        error! "Can't multiply that business"
      end
    end
    bind
  end
end

class Lib::CompileTime
  def self.new
    bind = Lib::Runtime.new
    bind
  end
end
