require "./slang/*"

module Slang
  # TODO Put your code here
end

macro error!(message)
  next {Slang::Object.nil, Slang::Error.new({{ message }}, 0, "")}
end

begin
  sc = Scanner.new ARGV[0]
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
  bind["raise"] = Slang::CrystalFn.new "raise" do |args|
    error! args.first.to_s
  end
  bind["println"] = Slang::CrystalFn.new "println" do |args|
    puts args.join(" ")
    no_error! Slang::Object.nil
  end

  bind["<="] = Slang::CrystalFn.new "<=" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      no_error! Slang::Boolean.new a.value <= b.value
    elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
      no_error! Slang::Boolean.new a.value <= b.value
    else
      error! "Can't compare that business"
    end
  end

  bind["+"] = Slang::CrystalFn.new "+" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      no_error! Slang::Number.new a.value + b.value
    elsif a.is_a?(Slang::Str) && b.is_a?(Slang::Str)
      no_error! Slang::Str.new a.value + b.value
    else
      error! "Can't add that business"
    end
  end

  bind["-"] = Slang::CrystalFn.new "-" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      no_error! Slang::Number.new a.value - b.value
    else
      error! "Can't subtract that business"
    end
  end

  bind["*"] = Slang::CrystalFn.new "*" do |args|
    a = args[0]
    b = args[1]
    if a.is_a?(Slang::Number) && b.is_a?(Slang::Number)
      no_error! Slang::Number.new a.value * b.value
    else
      error! "Can't multiply that business"
    end
  end

  tree.value.each do |expr|
    bind.compile_time = true
    expanded, err = interpreter.expand_macros(expr, bind)
    if err
      puts err
      break
    end
    bind.compile_time = false
    res, err = interpreter.eval(expanded, bind)
    if err
      puts err
      break
    end
  end
rescue sc : CompileError
  puts sc
  puts sc.inspect_with_backtrace
  exit 65
end
