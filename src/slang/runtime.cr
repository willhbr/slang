require "./objects"

module Slang
  class Splice < Object
    def initialize(@body : Object)
    end

    def truthy?
      @body.truthy?
    end

    def into(outer : Slang::List)
      b = @body
      if b.is_a? Slang::List
        b.each do |elem|
          outer << elem
        end
      else
        outer << b
      end
    end
  end

  class CrystalFn < Object
    def initialize(@name : String, &@block : Array(Object) -> Object)
    end

    def to_s(io)
      io << @name
    end

    def truthy?
      true
    end

    def call(args)
      @block.call args
    end
  end

  class Function < Object
    property arg_names
    property captured
    property body

    def initialize(@arg_names : Array(Identifier), @captured : Bindings, @body : Slang::List)
    end

    def truthy?
      true
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
