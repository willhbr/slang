require "./slang/*"

module SlangRunner
  extend self

  def read_from(name, string)
    parse Scanner.from_string(name, string)
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
      val = Interpreter.expand_macros(expr, bindings)
      res << val
    end
    res
  end

  def execute(bindings, program)
    return unless program
    res = nil
    program.each do |expr|
      res = Interpreter.eval(expr, bindings, false)
    end
    res
  end
end
