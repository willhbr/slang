require "./spec_helper"

describe Slang do
  # TODO: Write tests

  it "runs a file" do
    r = Runner.new
    tree = r.read "./spec/test.clj"
    tree = r.compile tree
    r.execute tree
  end

end
