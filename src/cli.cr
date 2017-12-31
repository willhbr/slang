require "./slang"
require "readline"

class Prompter
  include Readline
  @@run : Immutable::Map(String, Slang::Object) = Lib::Runtime.new
  @@compile : Immutable::Map(String, Slang::Object) = Lib::CompileTime.new

  Readline.autocomplete do |string|
    defs = @@run["*ns*"].as(NSes).current.defs.keys.select &.starts_with?(string)
    defs + @@run.keys
  end

  def read
    so_far = ""
    prompt = " |> "
    loop do
      if line = readline prompt, true
        so_far += '\n'
        so_far += line
      else
        exit # TODO do this more better
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
      tree = SlangRunner.compile @@compile, tree
      SlangRunner.execute @@run.set("_", prev), tree
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
  end
end

if ARGV.size == 0
  p = Prompter.new
  p.repl
else
  begin
    tree = SlangRunner.read(ARGV[0])
    run = Lib::Runtime.new
    compile = Lib::CompileTime.new
    tree = SlangRunner.compile(compile, tree)
    SlangRunner.execute(run, tree)
  rescue s : Slang::Error
    puts s
  rescue compiler_failed
    puts "COMPILER FAILED"
    puts compiler_failed.inspect_with_backtrace
  end
end

