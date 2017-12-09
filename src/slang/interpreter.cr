require "./objects"

class Bindings
  setter compile_time
  getter previous
  @previous : Bindings?
  @bound = {} of String => Slang::Object

  def initialize(@previous = nil, @compile_time = true)
  end

  def compile_time?
    @compile_time
  end

  def topmost
    top = self
    while top.previous != nil
      top = top.previous.as(Bindings)
    end
    top
  end

  def [](k)
    v = @bound[k]?
    return v unless v.nil?
    if p = @previous
      return p[k]
    else
      raise "Undefined variable #{k}"
    end
  end

  def []?(k)
    v = @bound[k]?
    return v unless v.nil?
    if p = @previous
      return p[k]?
    else
      nil
    end
  end

  def []=(k, v)
    @bound[k] = v
  end

  def to_s(io)
    @bound.each do |name, val|
      io << name
      io << ' '
      io << val
      io << '\n'
    end
    if prev = @previous
      prev.to_s io
    end
  end
end

class Interpreter
  def self.expand_with_splice_quotes(ast, bindings, klass, in_macro) : Slang::Result
    res = Array(Slang::Object).new
    ast.each do |node|
      expanded = try! expand_unquotes(node, bindings, in_macro)
      if expanded.is_a? Slang::Splice
        expanded.into res
      else
        res << expanded
      end
    end
    no_error! klass.from res
  end

  def self.expand_unquotes(ast : Slang::Object, bindings, in_macro) : Slang::Result
    case ast
    when Slang::Vector
      expand_with_splice_quotes(ast, bindings, Slang::Vector, in_macro)
    when Slang::List
      if (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote"
        expand_and_eval(ast[1], bindings, in_macro)
      elsif (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote-splice"
        inner = try! eval(ast[1], bindings, in_macro)
        no_error! Slang::Splice.new(inner)
      else
        expand_with_splice_quotes(ast, bindings, Slang::List, in_macro)
      end
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |k, v|
        result[try! expand_and_eval(k, bindings, in_macro)] = try! expand_and_eval(v, bindings, in_macro)
      end
      return no_error! Slang::Map.new result
    else
      no_error! ast
    end
  end

  def self.expand_and_eval(ast, bindings, in_macro) : Slang::Result
    eval(try!(expand_macros(ast, bindings)), bindings, in_macro)
  end

  def self.expand_macros(ast, bindings) : Slang::Result
    case ast
    when Slang::Vector
      ast.each_with_index do |node, idx|
        ast = ast.set(idx, try! expand_macros(node, bindings))
      end
      return no_error! ast
    when Slang::List
      if (first = ast.first) && first.is_a?(Slang::Identifier)
        case first.value
        when "quote"
          return no_error! ast
        when "macro"
          args = ast[1]
          return error! "args must be vector" unless args.is_a? Slang::Vector
          arguments = Array(Slang::Identifier).new
          splat_started = false
          splat_arg = nil
          args.each do |arg|
            return error! "Args must be identifiers" unless arg.is_a? Slang::Identifier
            if arg.value == "&"
              splat_started = true
              next
            end
            if splat_started
              splat_arg = arg
              break
            end
            arguments << arg
          end
          body = Array(Slang::Object).new
          ast.from(2).each do |node|
            body << try! expand_macros(node, bindings)
          end
          return no_error! Slang::Macro.new(arguments, bindings, Slang::List.from(body), splat_arg)
        when "def"
          name = ast[1]
          raise "name must be identifier" unless name.is_a? Slang::Identifier
          result = try! expand_macros(ast[2], bindings) 
          bindings.topmost[name.value] = result
          exp = Slang::List.create(Slang::Identifier.new("def"), name, result)
          return no_error! exp
        else
          if (mac = bindings[first.value]?) && mac.is_a?(Slang::Macro)
            binds = Bindings.new mac.captured
            values = ast.data
            mac.arg_names.each_with_index do |name, idx|
              binds[name.value] = values[idx]
            end

            if splat = mac.splat_name
              rest = Array(Slang::Object).new
              values.from(mac.arg_names.size).each do |arg|
                rest << arg
              end
              binds[splat.value] = Slang::Vector.from(rest)
            end

            mac.body.each_but_last do |expr|
              try! expand_and_eval(expr, binds, true)
            end
            if mac.body.empty?
              return no_error! nil
            else
              macro_result = try! expand_and_eval(mac.body.last, binds, true)
              return expand_macros(macro_result, bindings)
            end
          else
            return no_error! ast.map { |a| try! expand_macros(a, bindings) }
          end
        end
      else
        return no_error! ast.map { |a| try! expand_macros(a, bindings) }
      end
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |k, v|
        result[try! expand_macros(k, bindings)] = try! expand_macros(v, bindings)
      end
      return no_error! Slang::Map.new result
    when Slang::Wrapper
      return no_error! ast.value
    else
      no_error! ast
    end
  end

  def self.truthy?(value)
    value != nil
  end

  def self.eval(ast : Slang::Object, bindings, in_macro) : Slang::Result
    loop do
      return eval_node(ast, bindings, in_macro) unless ast.is_a? Slang::List
      return eval_node(ast, bindings, in_macro) if ast.is_a? Slang::Vector

      raise "Can't eval empty list" if ast.empty?

      if (first = ast.first) && first.is_a?(Slang::Identifier)
        name = first.value
        case name
        when "let"
          inner = Bindings.new bindings
          binds = ast[1]
          return error! "bindings must be a vector" unless binds.is_a? Slang::Vector
          return error! "must give bindings in key-value pairs" unless binds.size % 2 == 0
          binds.each_slice(2) do |assignment|
            name, value = assignment
            return error! "name must be identifier, got #{name}" unless name.is_a? Slang::Identifier
            inner[name.value] = try! eval(value, inner, in_macro)
          end
          bindings = inner
          ast.rest.each_but_last do |expr|
            try! eval(expr, bindings, in_macro)
          end
          ast = ast.last
          next
        when "do"
          ast.each_but_last do |expr|
            try! eval(expr, bindings, in_macro)
          end
          ast = ast.last
          next

        # I really don't know about these...
        when "quote"
          raise "Can't quote outside macro" unless in_macro
          return expand_unquotes(ast[1], bindings, in_macro)
        when "unquote"
          raise "Can't unquote outside macro" unless in_macro
          return eval(ast[1], bindings, in_macro)
        when "unquote-splice"
          raise "Can't unquote-splice outside macro" unless in_macro
          inner = try! eval(ast[1], bindings, in_macro)
          return no_error! Slang::Splice.new(inner)

        when "def"
          name = ast[1]
          return error! "name must be identifier" unless name.is_a? Slang::Identifier
          res = try! eval(ast[2], bindings, in_macro)
          bindings.topmost[name.value] = res
          return no_error! res
        when "fn"
          args = ast[1]
          return error! "args must be vector" unless args.is_a? Slang::Vector
          arguments = Array(Slang::Identifier).new
          splat_started = false
          splat_arg = nil
          args.each do |arg|
            return error! "Args must be identifiers" unless arg.is_a? Slang::Identifier
            if arg.value == "&"
              splat_started = true
              next
            end
            if splat_started
              splat_arg = arg
              break
            end
            arguments << arg
          end
          return no_error! Slang::Function.new(arguments, bindings, ast.data.data, splat_arg)
        when "if"
          cond = try! eval(ast[1], bindings, in_macro)
          if truthy? cond
            return eval(ast[2], bindings, in_macro)
          elsif other = ast[3]?
            return eval(other, bindings, in_macro)
          else
            return no_error! nil
          end
        end
      end

      func = try! eval(ast.first, bindings, in_macro)

      if func.is_a? Slang::Function
        binds = Bindings.new func.captured
        values = ast.data
        func.arg_names.each_with_index do |name, idx|
          arg = values[idx]
          binds[name.value] = try! eval(arg, bindings, in_macro)
        end

        if splat = func.splat_name
          rest = Array(Slang::Object).new
          values.from(func.arg_names.size).each do |arg|
            rest.push(try! eval(arg, bindings, in_macro))
          end
          binds[splat.value] = Slang::Vector.from(rest)
        end

        func.body.each_but_last do |expr|
          try! eval(expr, binds, in_macro)
        end
        if func.body.empty?
          return no_error! nil
        else
          return eval(func.body.last, binds, in_macro)
        end
      else
        return error! "Can't call non-function" unless func.is_a? Slang::CrystalFn
        return func.call(ast.data.map_to_arr { |expr| try! eval(expr, bindings, in_macro) })
      end
    end
  end

  def self.eval_node(ast : Slang::Object, bindings, in_macro) : Slang::Result
    return case ast
    when Slang::Vector
      expand_with_splice_quotes(ast, bindings, Slang::Vector, in_macro)
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |key, value|      
        result[try! eval(key, bindings, in_macro)] = try! eval(value, bindings, in_macro)
      end
      no_error! Slang::Map.new(result)
    when Slang::Identifier
      no_error! bindings[ast.value]
    else
      no_error! ast
    end
  end
end
