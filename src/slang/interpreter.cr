require "./objects/*"


macro bind_put(var, key, value)
  {{ var }} = {{ var }}.set({{ key }}, {{ value }})
end

macro lookup(bindings, key)
  ({{ bindings }}[{{ key }}.value]? || {{ bindings }}["*ns*"].as(NSes)[{{ key }}])
end

macro lookup?(bindings, key)
  ({{ bindings }}[{{ key }}.value]? || {{ bindings }}["*ns*"].as(NSes)[{{ key }}]?)
end

class Interpreter
  macro make_fun(ast, type, &process)
    args = ast[1]
    error! "args must be vector" unless args.is_a? Slang::Vector
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
      if arg.value == "**"
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
    kw_args = Hash(String, Slang::Object).new
    kw_arg_name = nil
    values = Array(Slang::Object).new
    ast.rest.each do |arg|
      if arg.is_a? Slang::KeywordArg
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
    %func = ({{ func }})
    if %func.is_a? Slang::CrystalFn
      trace(%func.call(values, kw_args, bindings), first)
    else
      trace(%func.call(values, kw_args), first)
    end
  end

  def self.expand_with_splice_quotes(ast, bindings, klass, in_macro) : Slang::Result
    res = Array(Slang::Object).new
    ast.each do |node|
      expanded = expand_unquotes(node, bindings, in_macro)
      if expanded.is_a? Slang::Splice
        expanded.into res
      else
        res << expanded
      end
    end
    klass.from res
  end

  def self.expand_unquotes(ast : Slang::Object, bindings, in_macro) : Slang::Result
    case ast
    when Slang::Vector
      expand_with_splice_quotes(ast, bindings, Slang::Vector, in_macro)
    when Slang::List
      return ast if ast.empty?
      if (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote"
        expand_and_eval(ast[1], bindings, in_macro)
      elsif (first = ast.first) && first.is_a?(Slang::Identifier) && first.value == "unquote-splice"
        inner = eval(ast[1], bindings, in_macro)
        Slang::Splice.new(inner)
      else
        expand_with_splice_quotes(ast, bindings, Slang::List, in_macro)
      end
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |k, v|
        result[expand_and_eval(k, bindings, in_macro)] = expand_and_eval(v, bindings, in_macro)
      end
      return Slang::Map.new result
    else
      ast
    end
  end

  def self.expand_and_eval(ast, bindings, in_macro) : Slang::Result
    eval(expand_macros(ast, bindings), bindings, in_macro)
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
        case first.value
        when "ns"
          name = ast[1]
          raise "ns must be identifier" unless name.is_a? Slang::Identifier
          bindings["*ns*"].as(NSes).change_ns(name.value)
          return ast
        when "quote"
          return ast
        when "macro"
          return eval(ast, bindings, true)
        when "def"
          name = ast[1]
          error! "name must be identifier", first unless name.is_a? Slang::Identifier
          result = expand_macros(ast[2], bindings) 
          ns = bindings["*ns*"].as(NSes)
          ns[name.value] = result
          if result.responds_to? :"name="
            result.name = name.value
          end
          if result.responds_to? :"location="
            result.location = name.location
          end
          exp = Slang::List.create(first, name, result)
          return exp
        else
          mac = lookup?(bindings, first)
          if mac && (mac.is_a?(Slang::Macro) || mac.is_a?(Slang::CrystalMacro))
            call_fun mac do
              arg
            end
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

  def self.eval(ast : Slang::Object, bindings, in_macro) : Slang::Result
    return eval_node(ast, bindings, in_macro) unless ast.is_a? Slang::List

    error! "Can't eval empty list" if ast.empty?

    if (first = ast.first) && first.is_a?(Slang::Identifier)
      case first.value
      when "macro"
        puts "making macro"
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
          names << Slang::Atom.new(attr.value)
        end
        return Slang::Type.new names
      when "ns"
        name = ast[1]
        error! "ns must be identifier" unless name.is_a? Slang::Identifier
        bindings["*ns*"].as(NSes).change_ns(name.value)
        return nil
      when "let"
        inner = bindings
        binds = ast[1]
        error! "bindings must be a vector" unless binds.is_a? Slang::Vector
        error! "must give bindings in key-value pairs" unless binds.size % 2 == 0
        binds.each_slice(2) do |assignment|
          name, value = assignment
          error! "name must be identifier, got #{name}" unless name.is_a? Slang::Identifier
          bind_put inner, name.value, eval(value, inner, in_macro)
        end
        return ast.from(2).each_return_last { |expr|
          eval(expr, inner, in_macro)
        }
      when "do"
        return ast.rest.each_return_last { |expr|
          eval(expr, bindings, in_macro)
        }
      when "quote"
        return expand_unquotes(ast[1], bindings, in_macro)
      when "unquote"
        error! "Can't unquote outside macro" unless in_macro
        return eval(ast[1], bindings, in_macro)
      when "unquote-splice"
        error! "Can't unquote-splice outside macro" unless in_macro
        inner = eval(ast[1], bindings, in_macro)
        return Slang::Splice.new(inner)
      when "def"
        name = ast[1]
        error! "name must be identifier" unless name.is_a? Slang::Identifier
        result = eval(ast[2], bindings, in_macro)
        ns = bindings["*ns*"].as(NSes)
        ns[name.value] = result
        if result.responds_to? :"name="
          result.name = name.value
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

    func = eval(ast.first, bindings, in_macro)

    if func.responds_to? :call
      call_fun func do
        eval(arg, bindings, in_macro)
      end
    else
      error! "Can't call non-function: #{func}"
    end
  end

  def self.eval_node(ast : Slang::Object, bindings, in_macro) : Slang::Result
    return case ast
    when Slang::Vector
      expanded = expand_with_splice_quotes(ast, bindings, Slang::Vector, in_macro).as(Slang::Vector)
      expanded.each_with_index do |item, idx|
        expanded = expanded.set(idx, eval(item, bindings, in_macro))
      end
      return expanded
    when Slang::Map
      result = Hash(Slang::Object, Slang::Object).new
      ast.each do |key, value|      
        result[eval(key, bindings, in_macro)] = eval(value, bindings, in_macro)
      end
      Slang::Map.new(result)
    when Slang::Identifier
      lookup(bindings, ast)
    else
      ast
    end
  end
end
