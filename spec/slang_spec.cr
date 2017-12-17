require "./spec_helper"

describe Slang do
  # TODO: Write tests

  it "runs a file" do
    r = Runner.new
    tree = r.read "./spec/test.clj"
    tree = r.compile tree
    r.execute tree
  end

  it "calls a protocol method" do
    o = "Hello world"
    puts o.type
    puts o.send(Protocols.lengthable, "length", [o] of Slang::Object)
  end

end
