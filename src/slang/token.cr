class Token
  getter type : Symbol
  getter value : String | Int32 | Nil
  getter index : Int32
  getter path : String

  def initialize(@index, @path, @type, @value)
  end

  def parse_error(message)
    raise ParseError.new message, @index, @path
  end

  def to_s(io)
    if value.nil?
      io << type
    else
      io << value
    end
  end
end
