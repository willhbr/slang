require "./objects"

module Slang
  abstract class Fn < Object
    abstract def call(args)
  end

  class CrystalFn < Fn
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
end
