require "./token"

class Scanner
  @index = 0
  @line = 1
  @column = 1
  @input : IO
  @peeked : Char? = nil

  def initialize(@input)
  end

  def self.new(input : String)
    new IO::Memory.new(input.to_slice)
  end

  def advance?
    @index += 1
    @column += 1
    if peeked = @peeked
      @peeked = nil
      return peeked
    end
    char = @input.read_char
    return nil unless char
    char
  end

  def peek?
    if peeked = @peeked
      return peeked
    end
    @peeked = @input.read_char
    return @peeked
  end

  def advance_when(&block)
    if (peeked = peek?) && yield peeked
      advance?
      peeked
    else
      nil
    end
  end

  def each_token(&block)
    loop do
      char = advance?
      break unless char
      case char
        when '('
          yield sym(:"(")
        when ')'
          yield sym(:")")
        when '['
          yield sym(:"[")
        when ']'
          yield sym(:"]")
        when '\''
          yield sym(:"'")
        when '`'
          yield sym(:"`")
        when '~'
          if peek? == '@'
            advance?
            yield sym(:"~@")
          else
            yield sym(:"~")
          end
        when '{'
          yield sym(:"{")
        when '}'
          yield sym(:"}")
        when ':'
          iden = identifier("")
          yield sym(:ATOM, iden)
        when ' ', '\t'
          next
        when '\n'
          @line += 1
          @column = 1
          next
        when '"'
          yield sym(:STRING, string)
        else
          if is_digit(char)
            yield sym(:NUMBER, number(char))
          elsif is_iden_start(char)
            yield sym(:IDENTIFIER, identifier(char))
          else
            raise "Invalid character on line #{@line}: '#{char}' (#{char.ord})"
          end
      end
    end
    yield sym(:EOF)
  end

  def sym(type, value=nil)
    Token.new @line, @column, type, value
  end

  def is_digit(char)
    '0' <= char <= '9'
  end

  IDEN = {
    '<',
    '>',
    '=',
    '+',
    '-',
    '?',
    '/',
    '.',
    ',',
    '|',
    '!',
    '$',
    '%',
    '^',
    '&',
    '*'
  }

  def is_iden_start(char)
    'a' <= char <= 'z' || 'A' <= char <= 'Z' || char == '_' || IDEN.includes?(char)
  end

  def is_iden(char)
    is_iden_start(char) || is_digit(char)
  end

  def string
    buffer = ""
    while char = advance_when { |char| char != '"' }
      buffer = buffer + char
    end
    advance?
    buffer
  end

  def number(start)
    buffer = "#{start}"
    while char = advance_when { |char| is_digit(char) }
      buffer = buffer + char
    end
    buffer.to_i
  end

  def identifier(start)
    buffer = "#{start}"
    while char = advance_when { |char| is_iden(char) }
      buffer = buffer + char
    end
    buffer
  end
end
