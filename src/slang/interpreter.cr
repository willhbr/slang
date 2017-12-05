require "./objects"

class Bindings
  getter previous
  @previous : Bindings?
  @bound = {} of String => Slang::Object

  def initialize(@previous = nil)
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
  def eval(ast, bindings=Bindings.new)
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
          raise "bindings must be a vector" unless binds.is_a? Slang::Vector
          raise "must give bindings in key-value pairs" unless binds.size % 2 == 0
          binds.each_slice(2) do |assignment|
            name, value = assignment
            raise "name must be identifier, got #{name}" unless name.is_a? Slang::Identifier
            inner[name.value] = eval(value, inner)
          end
          return eval(ast[2], inner)
        when "do"
          ast[1..-2].each do |expr|
            eval(expr, bindings)
          end
          return eval(ast[-1], bindings)
        when "def"
          name = ast[1]
          raise "name must be identifier" unless name.is_a? Slang::Identifier
          return bindings.topmost[name.value] = eval(ast[2], bindings)
        when "fn"
          args = ast[1]
          raise "args must be vector" unless args.is_a? Slang::Vector
          args = args.value.map do |arg|
            raise "Args must be identifiers" unless arg.is_a? Slang::Identifier
            arg.as(Slang::Identifier)
          end
          return Slang::Function.new args, bindings, Slang::List.new(ast.data[1..-1])
        when "if"
          cond = eval(ast[1], bindings)
          if cond.truthy?
            return eval(ast[2], bindings)
          elsif other = ast[3]?
            return eval(other, bindings)
          else
            return Slang::Object.nil
          end
        end
      end

      func = eval(ast.first, bindings)

      if func.is_a? Slang::Function
        binds = Bindings.new func.captured
        ast.data.each_with_index do |arg, idx|
          binds[func.arg_names[idx].value] = eval(arg, bindings)
        end
        func.body[0..-2].each do |expr|
          eval(expr, binds)
        end
        return eval(func.body[-1], binds)
      else
        raise "Can't call non-function" unless func.is_a? Slang::Fn
        return func.call(ast.data.map { |expr| eval(expr, bindings) })
      end
    end
  end

  def eval_node(ast, bindings)
    return case ast
    when Slang::Vector
      result = Slang::Vector.new
      ast.each do |value|      
        result << eval(ast, bindings)
      end
      result
    when Slang::Map
      result = Slang::Map.new
      ast.each do |key, value|      
        result[eval(key, bindings)] = eval(value, bindings)
      end
      result
    when Slang::Identifier
      bindings[ast.value]
    when Slang::Number, Slang::Str, Slang::Empty, Slang::Atom, Slang::Boolean
      ast
    else
      raise "Unknown type passed to eval_node: #{ast}"
    end
  end
end
