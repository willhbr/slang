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
    prompt = "> "
    loop do
      if line = readline prompt, true
        so_far += line
      else
        exit # TODO do this more better
      end
      begin
        tree = SlangRunner.read_from so_far
        return tree
      rescue UnexpectedEOF
        prompt = "* "
      end
    end
  end

  def eval(tree)
    tree = SlangRunner.compile @@compile, tree
    SlangRunner.execute @@run, tree
  end

  def repl
    loop do
      tree = read
      res = eval(tree)
      puts "-> #{res}"
    end
  end
end

p = Prompter.new
p.repl
