require "../slang/interpreter"

module Slang
  abstract class Callable
    abstract def call(args, kw_args) : Result
  end

  class CrystalFn < Callable
    def initialize(@name : String, &@block : Array(Object) -> Result)
    end

    def to_s(io)
      io << @name
    end

    def call(args, kw_args)
      @block.call args
    end
  end

  class CrystalMacro < CrystalFn
  end

  class Function < Callable
    property arg_names
    property splat_name
    property kw_name
    property captured
    property body
    property name : String? = nil
    property location : FileLocation

    def initialize(@arg_names : Array(Identifier), @captured : Bindings, @location,
                   @body : Slang::List, @splat_name : Identifier? = nil, @kw_name : Identifier? = nil)
    end

    def call(*args : Slang::Object)
      call(args)
    end

    def call(values, kw_args)
      binds = @captured
      values_idx = 0
      @arg_names.each do |name|
        if kw_args.has_key? name.value
          bind_put binds, name.value, kw_args.delete(name.value)
        else
          bind_put binds, name.value, values[values_idx]?
          values_idx += 1
        end
      end

      if splat = @splat_name
        rest = Array(Slang::Object).new
        values[@arg_names.size..-1].each do |arg|
          rest.push(arg)
        end
        bind_put binds, splat.value, Slang::Vector.from(rest)
      end

      if kw_name = @kw_name
        map = Slang::Map.new
        kw_args.each do |k, v|
          map = map.set(Slang::Atom.new(k), v)
        end
        bind_put binds, kw_name.value, map
      end

      is_macro = is_macro?

      return @body.each_return_last { |expr|
        trace Interpreter.eval(expr, binds, is_macro), @location
      }
    end

    def is_macro?; false end

    def to_s(io)
      if b = @name
        io << "fn-"
        io << b
      else
        io << "fn-"
      end
    end
  end

  class Macro < Function
    def is_macro?; true end

    def to_s(io)
      if b = @name
        io << "macro-"
        io << b
      else
        io << "macro-"
      end
    end
  end
end
