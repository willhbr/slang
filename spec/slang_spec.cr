require "./spec_helper"

describe Slang do


  run = Lib::Runtime.new
  run = run.set("assert", Slang::CrystalFn.new("assert") do |args|
    error! "Failed assertion: #{args[1]?}" unless args[0]
  end)
  comp = Lib::CompileTime.new(run)
  tests = [] of ->Nil
  comp = comp.set("testing", Slang::CrystalMacro.new("testing") do |ast|
    message = ast[0].as(String)
    tests << -> do
      it message do
        ast = ast[1..-1].map do |node|
          Interpreter.expand_macros(node, comp)
        end
        ast.each do |node|
          Interpreter.eval(node, run, false)
        end
      end
    end
    nil
  end)
  comp = comp.set("compile-time?", true)
  run = run.set("compile-time?", false)
  tree = SlangRunner.read "./spec/test.clj"
  tree = SlangRunner.compile comp, tree
  begin
    SlangRunner.execute run, tree
    tests.each do |test|
      test.call
    end
  rescue e : Slang::Error
    puts e
    fail "Assertion failed"
  end
end
