require "./slang"

begin
  sl = Runner.new
  tree = sl.read ARGV[0]
  tree = sl.compile tree
  puts sl.execute tree
rescue sc : CompileError
  puts sc
  puts sc.inspect_with_backtrace
  exit 65
end
