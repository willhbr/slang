require "./token"

class Scanner
  @index = 0
  @peeked : Char? = nil

  def initialize(@file_path : String)
    @input = File.open(@file_path)
  end

  def advance?
    if peeked = @peeked
      @peeked = nil
      @index += 1
      return peeked
    end
    char = @input.read_char
    return nil unless char
    @index += 1
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
        when ' ', '\t', '\n'
          next
        when '"'
          yield sym(:STRING, string)
        else
          if is_digit(char)
            yield sym(:NUMBER, number(char))
          elsif is_iden_start(char)
            val = identifier(char)
            if val.ends_with? ':'
              yield sym(:ATOM, val[0..-2])
            else
              yield sym(:IDENTIFIER, val)
            end
          else
            raise ParseError.new("Invalid character #{char} ", @index, @file_path)
          end
      end
    end
    yield sym(:EOF)
  end

  def sym(type, value=nil)
    Token.new @index, @file_path, type, value
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
    '*',
    ':'
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
