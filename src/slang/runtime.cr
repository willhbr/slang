require "./objects"

macro try!(call)
  if %res = {{ call }}
    %value, %error = %res
    if %error != nil
      return {nil, %error}
    end
    %value
  else
    raise "This should not happen"
  end
end

macro no_error!(call)
  { {{ call }}, nil}
end

macro error!(message)
  raise {{ message.stringify }}
  {nil, Slang::Error.new({{ message }}, 0, "")}
end
