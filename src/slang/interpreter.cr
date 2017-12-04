require "./objects"

class Interpreter
  property bindings : Hash(String, Slang::Object)

  @bindings = {} of String => Slang::Object

  def eval(object : Slang::Object)
    object.run(bindings)
  end

  def defn(name, &block)
    bindings[name] = Slang::CrystalFn.new name do |args|
      yield args
    end
  end

  def []=(name, object)
    bindings[name] = object
  end
end
