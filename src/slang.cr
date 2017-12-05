require "./slang/*"

module Slang
  # TODO Put your code here
end

File.open(ARGV[0]) do |file|
  sc = Scanner.new file
  tokens = [] of Token
  sc.each_token do |token|
    tokens.push token
  end
  index = 0
  parser = Parser.new do
    token = tokens[index]
    index += 1
    token
  end
  tree = parser.parse

  interpreter = Interpreter.new

  bind = Bindings.new
  bind["println"] = Slang::CrystalFn.new "println" do |args|
    puts args.join(" ")
    Slang::Object.nil
  end

  bind["<="] = Slang::CrystalFn.new "<=" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      Slang::Boolean.new a.value <= b.value
    elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
      Slang::Boolean.new a.value <= b.value
    else
      raise "Can't compare that business"
    end
  end

  bind["+"] = Slang::CrystalFn.new "+" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      Slang::Number.new a.value + b.value
    elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
      Slang::Str.new a.value + b.value
    else
      raise "Can't add that business"
    end
  end

  bind["-"] = Slang::CrystalFn.new "-" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      Slang::Number.new a.value - b.value
    else
      raise "Can't subtract that business"
    end
  end

  bind["*"] = Slang::CrystalFn.new "*" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      Slang::Number.new a.value * b.value
    else
      raise "Can't multiply that business"
    end
  end

  tree.value.each do |expr|
    interpreter.eval(expr, bind)
  end
end
