class Token
  getter line : Int32
  getter column : Int32
  getter type : Symbol
  getter value : String | Int32 | Nil

  def initialize(@line, @column, @type, @value)
  end

  def raise_here(message)
    raise "#{location} #{message}"
  end

  def location
    "#{line}:#{column}"
  end

  def to_s(io)
    if value.nil?
      io << type
    else
      io << value
    end
  end
end

struct Nil
  def raise_here(message)
    raise message
  end
end
