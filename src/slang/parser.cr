require "./objects"

class ExpectedEOF < Exception
end

class UnexpectedEOF < Exception
end

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
    program = Array(Slang::Object).new
    loop do
      begin
        obj = object()
        program << obj
      rescue ExpectedEOF
        break
      end
    end
    program
  end

  def object
    sym = pop_sym?
    raise ExpectedEOF.new unless sym
    case sym.type
    when :"("
      list sym, :")", Slang::List
    when :"["
      list sym, :"]", Slang::Vector
    when :"{"
      map(sym)
    when :"'", :"`"
      o = object
      raise UnexpectedEOF.new unless o
      Slang::List.quoted sym.location, o
    when :"~"
      o = object
      raise UnexpectedEOF.new unless o
      Slang::List.unquoted sym.location, o
    when :"~@"
      o = object
      return nil unless o
      Slang::List.unquote_spliced sym.location, o
    when :READER_MACRO
      reader_macro
    when :IDENTIFIER
      identifier(sym)
    when :NUMBER
      number(sym)
    when :STRING
      string(sym)
    when :ATOM
      atom(sym)
    when :KW_ARG
      kw_arg(sym)
    when :EOF
      raise ExpectedEOF.new
    else
      sym.parse_error "Syntax error: unexpected #{sym.type} '#{sym.value}'"
    end
  end

  def list(start, terminator, klass) : Slang::Object
    into = Array(Slang::Object).new
    loop do
      sym = peek_sym?
      unless sym
        raise UnexpectedEOF.new
      end
      if sym && sym.type == :EOF
        raise UnexpectedEOF.new
      end
      break if sym.type == terminator

      value = object()
      unless value
        raise UnexpectedEOF.new
      end
      into << value
    end
    pop_sym? # Get rid of terminator
    klass.from into
  end

  def map(start)
    into = Hash(Slang::Object, Slang::Object).new
    loop do
      key = peek_sym?
      raise UnexpectedEOF.new unless key
      raise UnexpectedEOF.new if key && key.type == :EOF
      break if key.type == :"}"
      if key.type == :KW_ARG
        key_obj = atom(key)
        pop_sym?
      else
        key_obj = object()
      end

      value = peek_sym?
      raise UnexpectedEOF.new unless value
      raise UnexpectedEOF.new if value && value.type == :EOF
      key.parse_error "Map literals must have an even number of elements" if key.type == :"}"
      value_obj = object()

      into[key_obj] = value_obj
    end
    pop_sym?
    Slang::Map.new into
  end

  def identifier(token)
    value = token.value.as(String)
    case value
    when "nil"
      nil
    when "true"
      true
    when "false"
      false
    else
      mod, _dot, var = value.partition('.')
      if var.empty?
        Slang::Identifier.new token.location, mod
      else
        Slang::Identifier.new token.location, var, mod
      end
    end
  end

  def reader_macro
    sym = pop_sym?
    raise UnexpectedEOF.new unless sym
    case sym.type
    when :IDENTIFIER
      name = identifier sym
      rest = reader_subject
      Slang::List.create name, rest
    else
      sym.parse_error ""
    end
  end

  def reader_subject
    sym = pop_sym?
    raise UnexpectedEOF.new unless sym
    case sym.type
    when :"["
      list sym, :"]", Slang::Vector
    when :"("
      list sym, :")", Slang::List
    when :"{"
      map sym
    when :REGEX_LITERAL, :STRING
      sym.value.as(String)
    else
      sym.parse_error "Unexpected token"
    end
  end

  def number(token)
    token.value.as(Int32)
  end

  def string(token)
    token.value.as(String)
  end

  def kw_arg(token)
    Slang::KeywordArg.new token.value.as(String)
  end

  def atom(token)
    Slang::Atom.new token.value.as(String)
  end
end
