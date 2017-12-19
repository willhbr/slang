require "immutable"

module Slang
  alias Vector = Immutable::Vector(Object)
  alias Map = Immutable::Map(Object, Object)

  class Immutable::Vector(T)
    def self.from(vals : Array(T))
      new vals
    end

    def each_but_last
      idx = 0
      stop_at = size - 2
      each_with_index do |item, idx|
        if idx == stop_at
          break
        end
        yield item
        idx += 1
      end
    end

    def to_s(io)
      io << '['
      first = true
      each do |item|
        io << ' ' unless first
        first = false
        item.to_s io
      end
      io << ']'
    end

    include Slang::CrystalSendable
    def type
      VectorType.instance
    end
  end

  class Immutable::Map(K, V)
    include Slang::CrystalSendable

    def type
      MapType.instance
    end
  end
end
