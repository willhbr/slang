require "./slang"

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

  runtime = Lib::Runtime.new
  compiletime = Lib::CompileTime.new

  tree.value.each do |expr|
    expanded, err = interpreter.expand_macros(expr, compiletime)
    if err
      puts err
      break
    end
    res, err = interpreter.eval(expanded, runtime)
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
