require "./token"

class Scanner
  @index = 0
  @line = 1
  @column = 1
  @current = '\0'
  @peeked : Char? = nil

  def self.from_file(file_path : String)
    new(file_path, File.open(file_path))
  end

  def self.from_string(name, string)
    new(name, IO::Memory.new(string.to_slice))
  end

  def initialize(@file_path : String, @input : IO)
  end

  private def advance_idx
    @index += 1
    @column += 1
    if @current == '\n'
      @line += 1
      @column = 0
    end
  end

  def advance?
    if peeked = @peeked
      @peeked = nil
      advance_idx
      return peeked
    end
    char = @input.read_char
    return nil unless char
    @current = char
    advance_idx
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

  def tokens
    toks = [] of Token
    each_token do |tok|
      toks << tok
    end
    toks
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
        when '@'
          yield sym(:"@")
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
        when ' ', '\t', '\n', ','
          next
        when '"'
          yield sym(:STRING, string)
        when '#'
          yield sym(:READER_MACRO)
        when '/'
          yield sym(:REGEX_LITERAL, regex)
        when ';'
          comment
          next
        else
          if is_digit(char)
            yield sym(:NUMBER, number(char))
          elsif is_iden_start(char)
            val = identifier(char)
            if val.ends_with? ':'
              yield sym(:KW_ARG, val[0..-2])
            else
              yield sym(:IDENTIFIER, val)
            end
          else
            raise ParseError.new("Invalid character #{char} ", current_file_location)
          end
      end
    end
    yield sym(:EOF)
  end

  def sym(type, value=nil)
    Token.new current_file_location, type, value
  end

  def current_file_location
    FileLocation.new @file_path, @line, @column
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

  # TODO maybe support some suffix flags?
  # Although the scanner has to know about it, which is kinda annoying
  def regex
    buffer = ""
    while char = advance_when { |char| char != '/' }
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

  def comment
    while advance_when { |char| char != '\n' }
    end
    nil
  end
end
