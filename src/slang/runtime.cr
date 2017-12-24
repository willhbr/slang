require "./objects"

macro error!(message, cause=nil)
  {% if cause == nil %}
    raise Slang::Error.new({{ message }}, Slang::Identifier.new FileLocation["th", 1, 2], "Stuff")
  {% else %}
    raise Slang::Error.new({{ message }}, ({{ cause }}).location)
  {% end %}
end

macro trace(expr, location)
  begin
    {{ expr }}
  rescue %error : Slang::Error
    %error.add_to_trace( {{ location }} ) if {{ location }}.is_a? FileLocation || {{ location }}.is_a? Slang::Identifier
    raise %error
  end
end
