require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NS
  property defs = Hash(String, Slang::Object).new

  delegate :[], :[]?, :[]=, to: @defs
end
