# require "./objects"
# require "./runtime"
# 
# class Bindings
#   @previous : Bindings?
#   @bound = {} of String => Slang::Object
#   def initialize(@previous = nil)
#   end
# 
#   def [](k)
#     v = @bound[k]?
#     return v unless v.nil?
#     if p = @previous
#       return p[k]
#     else
#       raise "Undefined variable #{k}"
#     end
#   end
# 
#   def []=(k, v)
#     @bound[k] = v
#   end
# end
# 
# class Expander
#   @global_bindings = Bindings.new
#   @in_quote = false
# 
#   def expand_list(list : Slang::List, bindings = Bindings.new)
#     return list if list.empty?
#     if list.first.is_a? Slang::Literal
#       case list.first.value
#       when "if"
#         expand_if(list, bindings)
#       when "let"
#         expand_let(list, bindings)
#       when "do"
#         expand_do(list, bindings)
#       when "def"
#         expand_def(list, bindings)
#       when "fn"
#         expand_fn(list, bindings)
#       when "macro"
#         expand_macro(list, bindings)
#       when "quote"
#         @in_quote = true
#         res = expand_quote(list, bindings)
#         @in_quote = false
#         res
#       when "unquote"
#         if @in_quote
#           @in_quote = false
#           res = expand_unquote(list, bindings)
#           @in_quote = true
#         else
#           raise "Cannot unquote outside of quote"
#         end
#       else
#         expand_call(list, bindings)
#       end
#     else
#       expand_call(list, bindings)
#     end
#   end
# 
#   def expand_identifier(var : Slang::Identifier, bindings)
#     bindings[var.value]
#   end
# 
#   def expand(expr, _bind)
#     case expr
#   end
# 
#   def expand_if(list, bindings)
#     raise "Only 3 arguments allowed for if" if list.size > 4
#     otherwise = list[3]? || Slang::Object.nil
#     Slang::If.new(
#       expand(list[1], bindings),
#       expand(list[2], bindings),
#       expand(otherwise, bindings)
#     )
#   end
# 
#   def expand_let(list, outer_bindings)
#     bindings = Bindings.new outer_bindings
#     binds = list[1]    
#     raise "bindings must be a vector" unless binds.is_a? Slang::Vector
#     raise "must give bindings in key-value pairs" unless binds.size % 2 == 0
#     (binds.size / 2).times do |idx|
#       name = binds[idx * 2]
#       raise "name must be identifier, got #{name}" unless name.is_a? Slang::Identifier
#       value = nb_expand(binds[idx * 2 + 1], bindings)
#       bindings[name.value] = value
#     end
# 
#     expand_do(list, bindings, from: 2)
#   end
# 
#   def expand_do(list, bindings, from = 1)
#     exprs = [] of Slang::Object
#     (from...list).size.each do |idx|
#       exprs << expand(list[idx], bindings)
#     end
#     Do.new exprs
#   end
# end
