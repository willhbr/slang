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
    
    bind = bind.set "*ns*", NSes.new.as(Slang::Object)

    func(bind, raise) do |args|
      error! args.first.to_s
    end
        
    func(bind, println) do |args|
      puts args.join(" ")
      no_error! nil
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

    func(bind, reduce) do |args|
      if args.size == 2
        func = args[0].as(Slang::Function)
        coll = args[1]
        next error! "Can't iterate on #{coll}" unless coll.responds_to? :each
        prev = nil
        coll.each do |item|
          if prev.nil?
            prev = item
          else
            prev, error = func.call([prev.as(Slang::Object), item.as(Slang::Object)])
          end
        end
        no_error! prev.as(Slang::Object)
      else
        func = args[0].as(Slang::Function)
        default = args[1]
        coll = args[2]
        next error! "Can't iterate on #{coll}" unless coll.responds_to? :each
        prev = default
        coll.each do |item|
          prev, error = func.call([prev.as(Slang::Object), item.as(Slang::Object)])
        end
        no_error! prev.as(Slang::Object)
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
