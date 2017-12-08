require "./objects"

class Lib::Runtime
  macro func(bind, name, &body)
    {% if name.is_a? SymbolLiteral %}
      name = {{ name }}.to_s
    {% else %}
      name = {{ name.stringify }}
    {% end %}
    {{bind}}[name] = Slang::CrystalFn.new name {{ body }}
  end

  def self.new
    bind = Bindings.new
    func(bind, raise) do |args|
      error! args.first.to_s
    end
        
    func(bind, println) do |args|
      puts args.join(" ")
      no_error! Slang::Object.nil
    end

    func(bind, first) do |args|
      a = args[0]
      next error! "Can't get first of non-list" unless a.is_a? Slang::List
      next no_error!(Slang::Object.nil) if a.empty?
      no_error! a.first
    end

    func(bind, rest) do |args|
      a = args[0]
      next error! "Can't get rest of non-list" unless a.is_a? Slang::List
      next no_error!(a) if a.empty?
      no_error! Slang::List.new(a.data)
    end

    func(bind, :<=) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
        no_error! Slang::Boolean.new a.value <= b.value
      elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
        no_error! Slang::Boolean.new a.value <= b.value
      else
        next error! "Can't compare that business"
      end
    end

    func(bind, :+) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
        no_error! Slang::Number.new a.value + b.value
      elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
        no_error! Slang::Str.new a.value + b.value
      else
       next error! "Can't add that business"
      end
    end

    func(bind, :-) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
        no_error! Slang::Number.new a.value - b.value
      else
        next error! "Can't subtract that business"
      end
    end

    func(bind, :*) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
        no_error! Slang::Number.new a.value * b.value
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
    # TODO
    bind
  end
end
