require "./objects"

macro defn(name, &block)
  i[{{ name.stringify }}] = Slang::CrystalFn.new {{ name.stringify }}, {{ block }}
end

def define_funcs(i)
  defn print do |args|
    puts args
    Slang::Object.nil
  end

  defn gets do |args|
    if val = gets
      Slang::Str.new val
    else
      Slang::Object.nil
    end
  end
end
