abstract class CompileError < Exception
  property location : FileLocation

  def initialize(@location)
  end
end

class ParseError < CompileError
  def initialize(@message : String, location)
    super(location)
  end

  def to_s(io)
    io << @message
    location.to_s(io)
  end
end

class EvalError < CompileError
  def initialize(@message : String)
    super(0, "")
  end

  def to_s(io)
    io << @message
  end
end
