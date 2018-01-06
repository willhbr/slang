require "./slang"

if ARGV.size == 0
  run : Immutable::Map(String, Slang::Object) = Lib::Runtime.new
  compile : Immutable::Map(String, Slang::Object) = Lib::CompileTime.new

  p = Prompter.new run, compile
  p.repl
  puts "Done"
elsif ARGV[0] == "compile"
  begin
    tree = SlangRunner.read(ARGV[1])
    compile = Lib::CompileTime.new
    tree = SlangRunner.compile(compile, tree)
    exit 1 unless tree
    File.open ARGV[1] + "c", "w" do |f|
      tree.each do |t|
        t.inspect f
        f << '\n'
      end
    end
  rescue s : Slang::Error
    puts s
  rescue compiler_failed
    puts "COMPILER FAILED"
    puts compiler_failed.inspect_with_backtrace
  end
elsif ARGV[0] == "run"
  begin
    tree = SlangRunner.read(ARGV[1])
    run = Lib::Runtime.new
    SlangRunner.execute(run, tree)
  rescue s : Slang::Error
    puts s
  rescue compiler_failed
    puts "COMPILER FAILED"
    puts compiler_failed.inspect_with_backtrace
  end
else
  begin
    tree = SlangRunner.read(ARGV[0])
    run = Lib::Runtime.new
    compile = Lib::CompileTime.new
    tree = SlangRunner.compile(compile, tree)
    SlangRunner.execute(run, tree)
  rescue s : Slang::Error
    puts s
  rescue compiler_failed
    puts "COMPILER FAILED"
    puts compiler_failed.inspect_with_backtrace
  end
end

