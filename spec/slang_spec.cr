require "./spec_helper"

describe Slang do

  it "runs a file" do
    comp = Lib::CompileTime.new
    comp = comp.set("compile-time?", true)
    run = Lib::Runtime.new
    run = run.set("compile-time?", false)
    puts comp["compile-time?"]
    assertions = 0
    run = run.set("assert", Slang::CrystalFn.new("assert") do |args|
      error! "Failed assertion: #{args[1]?}" unless args[0]
      assertions += 1
    end)
    tree = SlangRunner.read "./spec/test.clj"
    tree = SlangRunner.compile comp, tree
    SlangRunner.execute run, tree
    puts assertions
  end
end
