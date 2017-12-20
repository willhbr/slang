require "./objects"

macro try!(call, location=nil)
  if %res = {{ call }}
    %value, %error = %res
    unless %error.nil?
      {% if location != nil %}
        %error.add_to_trace( {{ location }} ) if {{ location }}.is_a? FileLocation || {{ location }}.is_a? Slang::Identifier
      {% end %}
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

macro error!(message, cause=nil)
  {% if cause == nil %}
    {nil, Slang::Error.new({{ message }}, Slang::Identifier.new FileLocation["th", 1, 2], "Stuff")}
  {% else %}
    {nil, Slang::Error.new({{ message }}, {{ cause }}.location)}
  {% end %}
end
