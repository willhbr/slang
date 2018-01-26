require "./objects/*"


macro bind_put(var, key, value)
  {{ var }} = {{ var }}.set({{ key }}, {{ value }})
end

class Interpreter
  macro make_fun(ast, type, &process)
    args = ast[1]
    check_type args, Slang::Vector
    arguments = Array(Slang::Identifier).new
    splat_started = false
    splat_arg = nil
    kwargs_arg = nil
    kw_started = false
    args.each do |arg|
      return error! "Args must be identifiers" unless arg.is_a? Slang::Identifier
      if arg.simple! == "&"
        splat_started = true
        next
      end
      if arg.simple! == "**"
        kw_started = true
        next
      end
      if splat_started
        splat_arg = arg
        splat_started = false
        next
      end
      if kw_started
        kwargs_arg = arg
        kw_started = false
        next
      end
      arguments << arg
    end
    %body = ({{ process.body }})
    return {{ type }}.new(arguments, bindings, first.location, %body, splat_arg, kwargs_arg)
  end

  macro call_fun(func, &process)
    %func = ({{ func }})
    kw_args = Hash(String, Slang::Object).new
    kw_arg_name = nil
    values = Array(Slang::Object).new
    ast.rest.each do |arg|
      if arg.is_a? Slang::Atom && arg.kw_arg?
        error! "Missing value for keyword arg: #{kw_arg_name}" if kw_arg_name
        kw_arg_name = arg.value
      elsif n = kw_arg_name
        kw_arg_name = nil
        kw_args[n] = ({{ process.body }})
      else
        values << ({{ process.body }})
      end
    end
    error! "Missing value for keyword arg: #{kw_arg_name}" if kw_arg_name
    if %func.is_a? Slang::CrystalFn
      trace(%func.call(values, kw_args, bindings), first)
    else
      trace(%func.call(values, kw_args), first)
    end
  end

  def self.expand_with_splice_quotes(ast, bindings, klass) : Slang::Result
    res = Array(Slang::Object).new
    ast.each do |node|
      expanded = expand_unquotes(node, bindings)
      if expanded.is_a? Slang::Splice
        expanded.into res
      else
        res << expanded
      end
    end
    klass.from res
  end

  def self.expand_unquotes(ast : Slang::Object, bindings) : Slang::Result
    case ast
    when Slang::Vector
      expand_with_splice_quotes(ast, bindings, Slang::Vector)
    when Slang::List
      return ast if ast.empty?
      if (first = ast.first) && first.is_a?(Slang::Identifier) && first.simple == "unquote"
        expand_and_eval(ast[1], bindings)
      elsif (first = ast.first) && first.is_a?(Slang::Identifier) && first.simple == "unquote-splice"
        inner = eval(ast[1], bindings)
        Slang::Splice.new(inner)
      else
        expand_with_splice_quotes(ast, bindings, Slang::List)
      end
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |k, v|
        result[expand_and_eval(k, bindings)] = expand_and_eval(v, bindings)
      end
      return Slang::Map.new result
    else
      ast
    end
  end

  def self.expand_and_eval(ast, bindings) : Slang::Result
    eval(expand_macros(ast, bindings), bindings)
  end

  def self.expand_macros(ast, bindings) : Slang::Result
    case ast
    when Slang::Vector
      ast.each_with_index do |node, idx|
        ast = ast.set(idx, expand_macros(node, bindings))
      end
      return ast
    when Slang::List
      if (first = ast.first) && first.is_a?(Slang::Identifier)
        case first.simple
        when "ns"
          name = ast[1]
          check_type name, Slang::Identifier, "ns must be identifier"
          ns = name.lookup?(bindings) || NS.new name.simple!
          dyn = bindings["*ns*"].as(Slang::Dynamic)
          dyn.value = ns
          return ast
        when "quote"
          return ast
        when "macro"
          return eval(ast, bindings)
        when "def"
          name, value = ast.rest.splat_first_2
          check_type name, Slang::Identifier
          result = expand_macros(value, bindings) 
          ns = bindings["*ns*"].as(Slang::Dynamic).value.as(NS)
          ns[name.simple!] = result
          if result.responds_to? :"name="
            result.name = name.simple!
          end
          if result.responds_to? :"location="
            result.location = name.location
          end
          return Slang::List.create(first, name, result)
        else
          mac = first.lookup? bindings
          if mac && (mac.is_a?(Slang::Macro) || mac.is_a?(Slang::CrystalMacro))
            result = (call_fun mac do
              arg
            end)
            return expand_macros(result, bindings)
          else
            return ast.map { |a| expand_macros(a, bindings) }
          end
        end
      else
        return ast.map { |a| expand_macros(a, bindings) }
      end
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |k, v|
        result[expand_macros(k, bindings)] = expand_macros(v, bindings)
      end
      return Slang::Map.new result
    else
      ast
    end
  end

  def self.truthy?(value)
    value != nil
  end

  def self.eval(ast : Slang::Object, bindings) : Slang::Result
    return eval_node(ast, bindings) unless ast.is_a? Slang::List

    error! "Can't eval empty list" if ast.empty?

    if (first = ast.first) && first.is_a?(Slang::Identifier)
      case first.simple
      when "macro"
        make_fun ast, Slang::Macro do
          body = Array(Slang::Object).new
          ast.from(2).each do |node|
            body << expand_macros(node, bindings)
          end
          Slang::List.from body
        end
      when "type"
        names = Array(Slang::Atom).new
        ast.data.each do |attr|
          return error! "Attributes must be identifiers" unless attr.is_a? Slang::Identifier
          names << Slang::Atom.new(attr.simple!)
        end
        return Slang::Type.new names
      when "ns"
        name = ast[1]
        check_type name, Slang::Identifier, "ns must be identifier"
        ns = name.lookup?(bindings) || NS.new name.simple!
        dyn = bindings["*ns*"].as(Slang::Dynamic)
        dyn.value = ns
        return nil
      when "let"
        inner = bindings
        binds = ast[1]
        check_type binds, Slang::Vector, "bindings must be a vector"
        error! "must give bindings in key-value pairs" unless binds.size % 2 == 0
        binds.each_slice(2) do |assignment|
          name, value = assignment
          check_type name, Slang::Identifier, "name must be identifier"
          bind_put inner, name.simple!, eval(value, inner)
        end
        return ast.from(2).each_return_last { |expr|
          eval(expr, inner)
        }
      when "do"
        return ast.rest.each_return_last { |expr|
          eval(expr, bindings)
        }
      when "quote"
        return expand_unquotes(ast[1], bindings)
      when "def"
        name, value = ast.rest.splat_first_2
        check_type name, Slang::Identifier, "name must be identifier"
        result = eval(value, bindings)
        ns = bindings["*ns*"].as(Slang::Dynamic).value.as(NS)
        ns[name] = result
        if result.responds_to? :"name="
          result.name = name.simple!
        end
        if result.responds_to? :"location="
          result.location = name.location
        end
        return result
      when "fn" # TODO Move working out the args into a macro?
        make_fun ast, Slang::Function do
          ast.from(2)
        end
      end
    end

    func = eval(ast.first, bindings)

    if func.responds_to? :call
      call_fun func do
        eval(arg, bindings)
      end
    else
      error! "Can't call non-function: #{func}"
    end
  end

  def self.eval_node(ast : Slang::Object, bindings) : Slang::Result
    return case ast
    when Slang::Vector
      expanded = expand_with_splice_quotes(ast, bindings, Slang::Vector).as(Slang::Vector)
      expanded.each_with_index do |item, idx|
        expanded = expanded.set(idx, eval(item, bindings))
      end
      return expanded
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |key, value|      
        result[eval(key, bindings)] = eval(value, bindings)
      end
      Slang::Map.new(result)
    when Slang::Identifier
      ast.lookup! bindings
    else
      ast
    end
  end
end
