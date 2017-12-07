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
      return p[k]
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
  end
end


class Interpreter
  def expand_with_splice_quotes(ast : Slang::List, bindings, klass) : Slang::Result
    res = klass.new
    ast.each do |node|
      expanded = try! expand_unquotes(node, bindings)
      if expanded.is_a? Slang::Splice
        expanded.into(res)
      else
        res << expanded
      end
    end
    no_error! res
  end

  def expand_unquotes(ast : Slang::Object, bindings) : Slang::Result
    case ast
    when Slang::Vector
      expand_with_splice_quotes(ast, bindings, Slang::Vector)
    when Slang::List
      if (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote"
        expand_and_eval(ast[1], bindings)
      elsif (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote-splice"
        inner = try! eval(ast[1], bindings)
        no_error! Slang::Splice.new(inner)
      else
        expand_with_splice_quotes(ast, bindings, Slang::List)
      end
    when Slang::Map
      result = Slang::Map.new
      ast.each do |k, v|
        result[try! expand_and_eval(k, bindings)] = try! expand_and_eval(v, bindings)
      end
      return no_error! result
    when Slang::Number, Slang::Str, Slang::Boolean, Slang::Atom, Slang::Empty, Slang::Identifier
      return no_error! ast
    else
      raise "Can't expand quotes: #{ast}"
    end
  end

  def expand_and_eval(ast, bindings) : Slang::Result
    eval(try!(expand_macros(ast, bindings)), bindings)
  end

  def expand_macros(ast, bindings) : Slang::Result
    case ast
    when Slang::Vector
      return no_error! ast.map { |a| try! expand_macros(a, bindings) }
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
          args.value.each do |arg|
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
          body = Slang::List.new
          ast[2..-1].each do |node|
            body << try! expand_macros(node, bindings)
          end
          return no_error! Slang::Macro.new(arguments, bindings, body, splat_arg)
        when "def"
          name = ast[1]
          raise "name must be identifier" unless name.is_a? Slang::Identifier
          result = try! expand_macros(ast[2], bindings) 
          bindings.topmost[name.value] = result
          exp = Slang::List.new
          exp << Slang::Identifier.new "def"
          exp << name
          exp << result
          return no_error! exp
        else
          if (mac = bindings[first.value]?) && mac.is_a?(Slang::Macro)
            binds = Bindings.new mac.captured
            values = ast.data
            mac.arg_names.each_with_index do |name, idx|
              binds[name.value] = values[idx]
            end

            if splat = mac.splat_name
              rest = Slang::Vector.new
              values[mac.arg_names.size..-1].each do |arg|
                rest << arg
              end
              binds[splat.value] = rest
            end

            mac.body[0..-2].each do |expr|
              try! expand_and_eval(expr, binds)
            end
            if mac.body.empty?
              return no_error! Slang::Object.nil
            else
              macro_result = try! expand_and_eval(mac.body[-1], binds)
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
      result = Slang::Map.new
      ast.each do |k, v|
        result[try! expand_macros(k, bindings)] = try! expand_macros(v, bindings)
      end
      return no_error! result
    when Slang::Number, Slang::Str, Slang::Boolean, Slang::Atom, Slang::Empty, Slang::Identifier
      return no_error! ast
    else
      raise "Unknown expandable: #{ast}"
    end
  end

  def eval(ast : Slang::Object, bindings) : Slang::Result
    loop do
      return eval_node(ast, bindings) unless ast.is_a? Slang::List
      return eval_node(ast, bindings) if ast.is_a? Slang::Vector

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
            inner[name.value] = try! eval(value, inner)
          end
          bindings = inner
          ast[2..-2].each do |expr|
            try! eval(expr, bindings)
          end
          ast = ast[-1]
          next
        when "do"
          ast[1..-2].each do |expr|
            try! eval(expr, bindings)
          end
          ast = ast[-1]
          next

        # I really don't know about these...
        when "quote"
          return expand_unquotes(ast[1], bindings)
        when "unquote"
          return eval(ast[1], bindings)
        # when "unquote-splice"
        #   inner = try! eval(ast[1], bindings)
        #   return no_error! Slang::Splice.new(inner)
        when "def"
          name = ast[1]
          return error! "name must be identifier" unless name.is_a? Slang::Identifier
          res = try! eval(ast[2], bindings)
          bindings.topmost[name.value] = res
          return no_error! res
        when "fn"
          args = ast[1]
          return error! "args must be vector" unless args.is_a? Slang::Vector
          arguments = Array(Slang::Identifier).new
          splat_started = false
          splat_arg = nil
          args.value.each do |arg|
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
          return no_error! Slang::Function.new(arguments, bindings, Slang::List.new(ast.data[1..-1]), splat_arg)
        when "if"
          cond = try! eval(ast[1], bindings)
          if cond.truthy?
            return eval(ast[2], bindings)
          elsif other = ast[3]?
            return eval(other, bindings)
          else
            return no_error! Slang::Object.nil
          end
        end
      end

      func = try! eval(ast.first, bindings)

      if func.is_a? Slang::Function
        binds = Bindings.new func.captured
        values = ast.data
        func.arg_names.each_with_index do |name, idx|
          arg = values[idx]
          binds[name.value] = try! eval(arg, bindings)
        end

        if splat = func.splat_name
          rest = Slang::Vector.new
          values[func.arg_names.size..-1].each do |arg|
            rest << try! eval(arg, bindings)
          end
          binds[splat.value] = rest
        end

        func.body[0..-2].each do |expr|
          try! eval(expr, binds)
        end
        if func.body.empty?
          return no_error! Slang::Object.nil
        else
          return eval(func.body[-1], binds)
        end
      else
        return error! "Can't call non-function" unless func.is_a? Slang::CrystalFn
        return func.call(ast.data.map { |expr| try! eval(expr, bindings) })
      end
    end
  end

  def eval_node(ast : Slang::Object, bindings) : Slang::Result
    return case ast
    when Slang::Vector
      result = Slang::Vector.new
      ast.each do |value|      
        result << try! eval(value, bindings)
      end
      no_error! result
    when Slang::Map
      result = Slang::Map.new
      ast.each do |key, value|      
        result[try! eval(key, bindings)] = try! eval(value, bindings)
      end
      no_error! result
    when Slang::Identifier
      no_error! bindings[ast.value]
    else
      no_error! ast
    end
  end
end
