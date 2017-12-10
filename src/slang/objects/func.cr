require "../slang/interpreter"

module Slang
  class CrystalFn
    def initialize(@name : String, &@block : Array(Object) -> Result)
    end

    def to_s(io)
      io << @name
    end

    def call(args)
      @block.call args
    end
  end

  class Function
    property arg_names
    property splat_name
    # TODO this doesn't do anything
    property kw_name
    property captured
    property body

    def initialize(@arg_names : Array(Identifier), @captured : Bindings,
                   @body : Slang::List, @splat_name : Identifier? = nil, @kw_name : Identifier? = nil)
    end

    def call(*args : Slang::Object)
      call(args)
    end

    def call(values)
      binds = @captured
      @arg_names.each_with_index do |name, idx|
        bind_put binds, name.value, values[idx]
      end

      if splat = @splat_name
        rest = Array(Slang::Object).new
        values[@arg_names.size..-1].each do |arg|
          rest.push(arg)
        end
        bind_put binds, splat.value, Slang::Vector.from(rest)
      end

      return no_error! @body.each_return_last { |expr|
        try! Interpreter.eval(expr, binds, false)
      }
    end

    def to_s(io)
      io << '('
      io << {{ @type.stringify }}
      io << " ["
      first = true
      @arg_names.each do |arg|
        io << ' ' unless first
        first = false
        arg.to_s(io)
      end
      io << "] "
      @body.each do |arg|
        arg.to_s(io)
      end
      if @body.empty?
        io << "nil"
      end
      io << ')'
    end
  end

  class Macro < Function
  end
end
