require "immutable"

module Slang

  class Identifier
    property value : String
    property location : FileLocation

    def initialize(@location, @value)
    end

    def to_s(io)
      io << @value
    end
  end

  struct Atom
    property value : String

    def initialize(@value)
    end

    def to_s(io)
      io << ':'
      io << @value
    end
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | Atom | Identifier | Splice |
                  Function | Callable | Instance | Regex | NSes | NS | Nil | Wrapper)

  alias Result = {Slang::Object, Slang::Error?}

  class Splice
    def initialize(@body : Object)
    end

    def into(outer)
      b = @body
      if b.is_a? Slang::List
        b.each do |elem|
          outer << elem
        end
      elsif b.is_a? Slang::Vector
        b.each do |elem|
          outer << elem
        end
      else
        outer << b
      end
    end
  end

  struct Wrapper
    property value : Bool | Nil

    def initialize(@value)
    end
  end

  class Error
    property trace : Array(Identifier)    

    def initialize(@message : String, cause : Identifier)
      @trace = [] of Identifier
    end

    def to_s(io)
      io << @message
    end

    def backtrace
      "#{@message}: #{@trace.join '\n'}"
    end
  end
end
struct Int32

end
class String

end
struct Bool

end
struct Atom

end
class Identifier

end
class Splice

end
class Function

end
class Callable

end
class Instance

end
class Regex

end
class NSes

end
class NS

end
struct Nil

end
struct Wrapper

end



