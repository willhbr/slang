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

    {% for method in [:to_s, :inspect] %}
      def {{ method.id }}(io : IO)
        io << '['
        first = true
        each do |item|
          io << ' ' unless first
          first = false
          item.{{ method.id }} io
        end
        io << ']'
      end
    {% end %}

    def [](iden : Slang::Atom)
      nil
    end

    def first_or_nil?
      self[0]?
    end

    def rest
      Slang::Vector.new self.to_a[1..-1]
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

    {% for method in [:to_s, :inspect] %}
      def {{ method.id }}(io : IO)
        io << '{'
        first = true
        each do |k, v|
          io << ' ' unless first
          first = false
          if k.is_a? Slang::Atom
            k.with_colon_suffix io
          else
            k.{{ method.id }} io
          end
          io << ' '
          v.to_s io
        end
        io << '}'
      end
    {% end %}
  end
end
