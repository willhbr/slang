abstract class CompileError < Exception
  @line_column : {Int32, Int32}?
  def initialize(@index : Int32, @file : String)
  end

  def line_column
    if line_col = @line_column
      return line_col 
    end
    idx = 0
    line_num = 1
    File.each_line(@file) do |line|
      if idx + line.size > @index
        @line_column = line_col = {line_num, @index - idx}
        return line_col
      end
      idx += line.size
    end
    return {line_num, 0}
  end
end

class ParseError < CompileError
  def initialize(@message : String, index, path)
    super(index, path)
  end

  def to_s(io)
    io << @message
    line, col = line_column
    io << line
    io << ':'
    io << col
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
