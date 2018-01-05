require "./spec_helper"

describe Slang do

  it "runs a file" do
    comp = Lib::CompileTime.new
    comp = comp.set("compile-time?", true)
    run = Lib::Runtime.new
    run = run.set("compile-time?", false)
    assertions = 0
    run = run.set("assert", Slang::CrystalFn.new("assert") do |args|
      error! "Failed assertion: #{args[1]?}" unless args[0]
      assertions += 1
    end)
    comp = comp.set("assert", Slang::CrystalFn.new("assert") do |args|
      error! "Failed assertion: #{args[1]?}" unless args[0]
      assertions += 1
    end)
    tree = SlangRunner.read "./spec/test.clj"
    tree = SlangRunner.compile comp, tree
    begin
      SlangRunner.execute run, tree
    rescue e : Slang::Error
      puts e
      fail "Assertion failed"
    end
    puts assertions
  end
end
