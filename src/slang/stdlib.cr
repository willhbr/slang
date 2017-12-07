require "./objects"

class Lib::Runtime
  def self.new
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
    bind
  end
end

class Lib::CompileTime
  def self.new
    bind = Lib::Runtime.new
    # TODO
    bind
  end
end
