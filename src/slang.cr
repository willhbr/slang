require "./slang/*"

module SlangRunner
  extend self

  def read_from(string)
    parse Scanner.from_string(string)
  end

  def read(file)
    parse Scanner.from_file(file)
  end

  private def parse(scanner)
    toks = scanner.tokens
    i = -1
    p = Parser.new do
      i += 1
      toks[i]?
    end
    p.parse
  end

  def compile(bindings, program)
    res = [] of Slang::Object
    program.each do |expr|
      val, err = Interpreter.expand_macros(expr, bindings)
      if err
        puts err
        return
      end
      res << val
    end
    res
  end

  def execute(bindings, program)
    return unless program
    res = nil
    program.each do |expr|
      res, err = Interpreter.eval(expr, bindings, false)
      if err
        puts err
        return
      end
    end
    res
  end
end
