require "./spec_helper"

describe Slang do
  # TODO: Write tests

  it "runs a file" do
    comp = Lib::CompileTime.new
    run = Lib::Runtime.new
    tree = SlangRunner.read "./spec/test.clj"
    tree = SlangRunner.compile comp, tree
    SlangRunner.execute run, tree
  end

  it "calls a protocol method" do
    o = "Hello world"
    puts o.type
    length = o.send(Protocols.lengthable, "length", [o] of Slang::Object, {} of String => Slang::Object)
    length.should eq(11)
    string = o.send(Protocols.printable, "->string", [o] of Slang::Object, {} of String => Slang::Object)
    string.should eq("Hello world")
  end
end
