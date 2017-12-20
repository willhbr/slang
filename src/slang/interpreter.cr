require "./objects/*"


macro bind_put(var, key, value)
  {{ var }} = {{ var }}.set({{ key }}, {{ value }})
end

macro lookup(bindings, key)
  ({{ bindings }}[{{ key }}]? || {{ bindings }}["*ns*"].as(NSes)[{{ key }}])
end

macro lookup?(bindings, key)
  ({{ bindings }}[{{ key }}]? || {{ bindings }}["*ns*"].as(NSes)[{{ key }}]?)
end

class Interpreter
  def self.expand_with_splice_quotes(ast, bindings, klass, in_macro) : Slang::Result
    res = Array(Slang::Object).new
    ast.each do |node|
      expanded = try! expand_unquotes(node, bindings, in_macro)
      # FIXME this shit is broken
      # expanded = try! eval(expanded, bindings, false) unless in_macro
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
        when "ns"
          name = ast[1]
          raise "ns must be identifier" unless name.is_a? Slang::Identifier
          bindings["*ns*"].as(NSes).change_ns(name.value)
          return no_error! ast
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
          return no_error! Slang::Macro.new(arguments, bindings, first.location, Slang::List.from(body), splat_arg)
        when "def"
          name = ast[1]
          raise "name must be identifier" unless name.is_a? Slang::Identifier
          result = try! expand_macros(ast[2], bindings) 
          ns = bindings["*ns*"].as(NSes)
          ns[name.value] = result
          if result.responds_to? :"name="
            result.name = name.value
          end
          if result.responds_to? :"location="
            result.location = name.location
          end
          exp = Slang::List.create(first, name, result)
          return no_error! exp
        else
          mac = lookup?(bindings, first.value)
          if mac && (mac.is_a?(Slang::Macro) || mac.is_a?(Slang::CrystalMacro))
            values = ast.data.map_to_arr &.itself
            return mac.call(values)
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
    return eval_node(ast, bindings, in_macro) unless ast.is_a? Slang::List

    raise "Can't eval empty list" if ast.empty?

    if (first = ast.first) && first.is_a?(Slang::Identifier)
      case first.value
      when "type"
        names = Array(Slang::Atom).new
        ast.data.each do |attr|
          return error! "Attributes must be identifiers" unless attr.is_a? Slang::Identifier
          names << Slang::Atom.new(attr.value)
        end
        return no_error! Slang::Type.new names
      when "ns"
        name = ast[1]
        raise "ns must be identifier" unless name.is_a? Slang::Identifier
        bindings["*ns*"].as(NSes).change_ns(name.value)
        return no_error! nil
      when "quote"
        return expand_unquotes(ast[1], bindings, in_macro)
      when "unquote"
        raise "Can't unquote outside macro" unless in_macro
        return eval(ast[1], bindings, in_macro)
      when "unquote-splice"
        raise "Can't unquote-splice outside macro" unless in_macro
        inner = try! eval(ast[1], bindings, in_macro)
        return no_error! Slang::Splice.new(inner)

      when "raise"
        return error! try!(eval(ast[1], bindings, in_macro)).to_s, first
      when "def"
        name = ast[1]
        return error! "name must be identifier" unless name.is_a? Slang::Identifier
        result = try! eval(ast[2], bindings, in_macro)
        ns = bindings["*ns*"].as(NSes)
        ns[name.value] = result
        if result.responds_to? :"name="
          result.name = name.value
        end
        if result.responds_to? :"location="
          result.location = name.location
        end
        return no_error! result
      when "fn" # TODO Move working out the args into a macro?
        args = ast[1]
        return error! "args must be vector" unless args.is_a? Slang::Vector
        arguments = Array(Slang::Identifier).new
        splat_started = false
        splat_arg = nil
        kwargs_arg = nil
        kw_started = false
        args.each do |arg|
          return error! "Args must be identifiers" unless arg.is_a? Slang::Identifier
          if arg.value == "&"
            splat_started = true
            next
          end
          if arg.value == "*"
            kw_started = true
            next
          end
          if splat_started
            splat_arg = arg
            next
          end
          if kw_started
            kwargs_arg = arg
            next
          end
          arguments << arg
        end
        return no_error! Slang::Function.new(arguments, bindings, first.location, ast.data.data, splat_arg, kwargs_arg)
      end
    end

    func = try! eval(ast.first, bindings, in_macro)

    if func.responds_to? :call
      values = ast.rest.map_to_arr do |arg|
        try! eval(arg, bindings, in_macro)
      end
      no_error! try!(func.call(values), first)
    else
      return error! "Can't call non-function" unless func.is_a? Slang::CrystalFn
      return func.call(ast.data.map_to_arr { |expr| try! eval(expr, bindings, in_macro) })
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
      no_error! lookup(bindings, ast.value)
    else
      no_error! ast
    end
  end
end
