require "./slang/*"
require "readline"

class Prompter
  include Readline
  property run : Bindings
  property compile : Bindings

  class EOFEntered < Exception
  end

  def initialize(@run, @compile)
    Readline.autocomplete do |string|
      defs = @run["*ns*"].as(NSes).current.defs.keys.select &.starts_with?(string)
      defs + @run.keys
    end
  end

  def read
    so_far = ""
    prompt = " |> "
    loop do
      if line = readline prompt, true
        so_far += '\n'
        so_far += line
      else
        raise EOFEntered.new
      end
      begin
        tree = SlangRunner.read_from "repl", so_far
        return tree
      rescue UnexpectedEOF
        prompt = "||> "
      end
    end
  end

  def eval(tree, prev=nil)
    begin
      tree = SlangRunner.compile @compile.set("_", prev), tree
      SlangRunner.execute @run.set("_", prev), tree
    rescue e : Slang::Error
      puts e
    rescue compiler_failed
      puts "COMPILER FAILED:"
      puts compiler_failed.inspect_with_backtrace
    end
  end

  def repl
    res = nil
    loop do
      tree = read
      res = eval(tree, res)
      puts "=> #{res}" if res
    end
    res
  rescue e : EOFEntered
    res
  end
end

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
      res = Interpreter.eval(expr, bindings)
    end
    res
  end
end
