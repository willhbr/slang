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

  define_funcs(interpreter)

  tree.value.each do |expr|
    puts interpreter.eval expr
  end
end
