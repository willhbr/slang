struct FileLocation
  property file : String
  property line : Int32
  property column : Int32

  def initialize(@file, @line, @column)
  end

  def self.[](file, line, column)
    new file, line, column
  end

  def to_s(io)
    io << @line << ':' << @column << ' ' << @file
  end
end

struct Token
  getter type : Symbol
  getter value : String | Int32 | Nil
  getter location : FileLocation

  def initialize(@location, @type, @value)
  end

  def parse_error(message)
    raise ParseError.new message, location
  end

  def to_s(io)
    if value.nil?
      io << type
    else
      io << value
    end
  end
end
