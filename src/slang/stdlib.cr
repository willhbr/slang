require "./objects"
require "../slang"

macro func(bind, name, type=Slang::CrystalFn, &body)
  {% if name.is_a? SymbolLiteral %}
    name = {{ name }}.to_s
  {% else %}
    name = {{ name.stringify }}
  {% end %}
  {{bind}}[name] = ({{ type }}.new(name) {{ body }})
end

class Lib::Runtime
  def self.new
    bind = Bindings.new

    ns = NSes.new

    Protocols::ALL.each do |proto|
      ns[proto.name.as(String)] = proto
    end
    
    bind = bind.set "*ns*", ns.as(Slang::Object)

    func(ns, println) do |args|
      puts args.join(" ")
      nil
    end

    func(ns, raise) do |args|
      error! args.first.to_s
    end

    func(ns, conj) do |args|
      first = args.first
      if first.is_a? Slang::List
        first.conjed(args[1])
      # elsif first.is_a? Slang::Vector
      #   vec = first.push(args[1].as(Slang::Object))
      #   vec
      else
        error! "can't add to #{first}"
      end
    end


    func(ns, first) do |args|
      a = args[0]
      next error! "Can't get first of non-list" unless a.responds_to? :first_or_nil?
      a.first_or_nil?
    end

    func(ns, rest) do |args|
      a = args[0]
      next error! "Can't get rest of non-list" unless a.responds_to? :rest
      a.rest
    end

    func(ns, :<=) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        a <= b
      elsif a.is_a?(String) && b.is_a?(String)
        a <= b
      else
        next error! "Can't compare that business"
      end
    end

    func(ns, :+) do |args|
      error! "Not enough args to +" if args.empty?
      if args.first.is_a? Int32
        args.reduce 0 do |a, b|
          error! "Can't add #{b}" unless b.is_a? Int32
          a + b
        end
      elsif args.first.is_a? String
        args.join
      end
    end

    func(ns, :-) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        a - b
      else
        next error! "Can't subtract that business"
      end
    end

    func(ns, :*) do |args|
      a = args[0]
      b = args[1]
      if a.is_a?(Int32) && b.is_a?(Int32)
        a * b
      else
        error! "Can't multiply that business"
      end
    end

    func(ns, slurp) do |args, _kw_args, bindings|
      first = args.first
      error! "Path must be string" unless first.is_a? String
      File.read(first)
    end

    func(ns, :"/=") do |args|
      error! "Not enough args for =" if args.size < 2
      next args[0] != args[1]
    end

    func(ns, :"=") do |args|
      error! "Not enough args for =" if args.size < 2
      next args[0] == args[1]
    end

    func(ns, :"*bindings*") do |ast, _kw_args, bindings|
      res = Slang::Map.new
      bindings.each do |k, v|
        res = res.set(Slang::Atom.new(k), v)
      end
      res
    end

    func(ns, isl) do |ast, _kw_args, bindings|
      run : Immutable::Map(String, Slang::Object) = Lib::Runtime.new
      compile : Immutable::Map(String, Slang::Object) = Lib::CompileTime.new

      p = Prompter.new run, compile
      puts "Starting repl"
      res = p.repl
      puts "finished"
      res
    end

    # FIXME this is absolutely not the right way to do this
    waiting = [] of Channel(Nil)
    func(ns, spawn) do |ast, _kw_args, bindings|
      chan = Channel(Nil).new
      waiting.push chan
      spawn do
        Interpreter.eval(ast.first, bindings)
        chan.send(nil)
      end
      nil
    end

    func(ns, join) do
      waiting.each &.receive
    end

    func(ns, :alias, type = Slang::CrystalMacro) do |args|
      old, new = args
      ns.alias_to(old.as(Slang::Identifier).simple!, new.as(Slang::Identifier).simple!)
      nil
    end

    func(ns, eval) do |ast, _kw_args, bindings|
      Interpreter.expand_and_eval ast.first, bindings
    end

    tree = SlangRunner.read_from("stdlib.clj", {{ `cat ./src/stdlib.clj`.stringify }})
    tree = SlangRunner.compile(bind, tree)
    SlangRunner.execute(bind, tree)

    bind
  end
end

class Lib::CompileTime
  def self.new(runtime = Lib::Runtime.new)
    bind = runtime

    ns = bind["*ns*"].as(NSes)

    func(ns, :"expand-macros", type = Slang::CrystalMacro) do |ast, _kw_args, bindings|
      Interpreter.expand_macros(ast[0], bindings)
    end

    bind
  end
end
