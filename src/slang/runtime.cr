require "./objects"

macro try!(call, location=nil)
  {% if location == nil %}
    {{ call }}
  {% else %}
    begin
      {{ call }}
    rescue %error : Slang::Error
      %error.add_to_trace( {{ location }} ) if {{ location }}.is_a? FileLocation || {{ location }}.is_a? Slang::Identifier
      raise %error
    end
  {% end %}
end

macro no_error!(call)
  {{ call }}
end

macro error!(message, cause=nil)
  {% if cause == nil %}
    raise Slang::Error.new({{ message }}, Slang::Identifier.new FileLocation["th", 1, 2], "Stuff")
  {% else %}
    raise Slang::Error.new({{ message }}, ({{ cause }}).location)
  {% end %}
end
