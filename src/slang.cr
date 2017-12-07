require "./slang/*"

class Runner
  property runtime : Bindings
  property compile_time : Bindings

  def initialize
    @runtime = Lib::Runtime.new
    @compile_time = Lib::CompileTime.new
  end

  @interpreter = Interpreter.new

  def read(file)
    toks = Scanner.new(file).tokens
    i = -1
    p = Parser.new do
      i += 1
      toks[i]?
    end
    p.parse
  end

  def compile(program)
    res = [] of Slang::Object
    program.each do |expr|
      val, err = @interpreter.expand_macros(expr, @compile_time)
      if err
        puts err
        return
      end
      res << val
    end
    res
  end

  def execute(program)
    return unless program
    res = Slang::Object.nil
    program.each do |expr|
      res, err = @interpreter.eval(expr, @compile_time)
      if err
        puts err
        return
      end
    end
    res
  end
end
