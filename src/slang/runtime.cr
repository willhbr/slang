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
    def initialize(@name : String, &@block : Array(Object) -> Result)
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
    property splat_name
    property captured
    property body

    def initialize(@arg_names : Array(Identifier), @captured : Bindings,
                   @body : Slang::List, @splat_name : Identifier? = nil)
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
  alias Result = {Slang::Object, Slang::Error?}
end

macro try!(call)
  if %res = {{ call }}
    %value, %error = %res
    if %error != nil
      return {Slang::Object.nil, %error}
    end
    %value
  else
    raise "This should not happen"
  end
end

macro no_error!(call)
  { {{ call }}, nil}
end

macro error!(message)
  {Slang::Object.nil, Slang::Error.new({{ message }}, 0, "")}
end
