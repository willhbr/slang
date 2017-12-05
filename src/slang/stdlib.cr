require "./objects"

# macro defn(name, &block)
#   i[{{ name }}.to_s] = Slang::CrystalFn.new {{ name }}.to_s, {{ block }}
# end
# 
# def define_funcs(i)
#   defn :print do |args|
#     puts args
#     Slang::Object.nil
#   end
# 
#   defn :gets do |args|
#     if val = gets
#       Slang::Str.new val
#     else
#       Slang::Object.nil
#     end
#   end
# 
#   defn :if do |args|
#     cond = args.first
#     if i.eval(cond).truthy?
#       i.eval args[1]
#     elsif otherwise = args[2]?
#       i.eval otherwise
#     else
#       Slang::Object.nil
#     end
#   end
# 
#   defn :fn do |args|
#     Slang::Object.nil
#   end
# 
#   defn :def do |args|
# 
#     Slang::Object.nil
#   end
# 
#   defn :let do |args|
#     
#     Slang::Object.nil
#   end
# 
#   defn :macro do |args|
#     
#   end
# end
