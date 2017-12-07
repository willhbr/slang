require "./objects"

class Parser
  @finished = false
  @peeked : Token? = nil


  def initialize(&@retriever : ->Token?)
  end

  def pop_sym?
    return nil if @finished
    if peeked = @peeked
      @peeked = nil
      return peeked
    end
    sym = @retriever.call
    return nil unless sym
    @finished = true if sym.type == :EOF
    sym
  end

  def peek_sym?
    return nil if @finished
    if peeked = @peeked
      return peeked
    end
    peeked = @retriever.call
    return nil unless peeked
    @finished = true if peeked.type == :EOF
    @peeked = peeked
    peeked
  end

  def parse
    program = Slang::List.new
    loop do
      obj = object()
      break unless obj
      program << obj
    end
    program
  end

  def object
    sym = pop_sym?
    return nil unless sym
    case sym.type
    when :"("
      list sym, :")"
    when :"["
      list sym, :"]", Slang::Vector
    when :"{"
      map(sym)
    when :"'", :"`"
      o = object
      return nil unless o
      Slang::List.quoted << o
    when :"~"
      o = object
      return nil unless o
      Slang::List.unquoted << o
    when :"~@"
      o = object
      return nil unless o
      Slang::List.unquote_spliced << o
    when :IDENTIFIER
      identifier(sym)
    when :NUMBER
      number(sym)
    when :STRING
      string(sym)
    when :ATOM
      atom(sym)
    when :EOF
      nil
    else
      sym.parse_error "Syntax error: unexpected #{sym.type} '#{sym.value}'"
    end
  end

  def list(start, terminator, klass=Slang::List)
    into = klass.new
    loop do
      sym = peek_sym?
      unless sym
        start.parse_error "Unexpected EOF"
      end
      if sym && sym.type == :EOF
        sym.parse_error "Unexpected EOF"
      end
      break if sym.type == terminator

      value = object()
      unless value
        raise "Unexpected EOF"
      end
      into << value
    end
    pop_sym? # Get rid of terminator
    into
  end

  def map(start)
    into = Slang::Map.new
    loop do
      key = peek_sym?
      start.parse_error "Unexpected EOF" unless key
      key.parse_error "Unexpected EOF" if key && key.type == :EOF
      break if key.type == :"}"
      key_obj = object()
      raise "Unexpected EOF" unless key_obj

      value = peek_sym?
      start.parse_error "Unexpected EOF" unless value
      value.parse_error "Unexpected EOF" if value && value.type == :EOF
      key.parse_error "Map literals must have an even number of elements" if key.type == :"}"
      value_obj = object()
      raise "Unexpected EOF" unless value_obj

      into[key_obj] = value_obj
    end
    pop_sym?
    into
  end

  def identifier(token)
    value = token.value.as(String)
    case value
    when "nil"
      Slang::Object.nil
    when "true"
      Slang::Boolean.new true
    when "false"
      Slang::Boolean.new false
    else
      Slang::Identifier.new value
    end
  end

  def number(token)
    Slang::Number.new token.value.as(Int32)
  end

  def string(token)
    Slang::Str.new token.value.as(String)
  end

  def atom(token)
    Slang::Atom.new token.value.as(String)
  end
end