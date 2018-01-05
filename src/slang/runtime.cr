require "./objects"

macro error!(message, cause=nil)
  {% if cause == nil %}
    raise Slang::Error.new({{ message }})
  {% else %}
    raise Slang::Error.new({{ message }}, ({{ cause }}).location)
  {% end %}
end

macro trace(expr, location)
  begin
    {{ expr }}
  rescue %error : Slang::Error
    # FIXME this is the type inference bug again
    if ({{ location }}).is_a? FileLocation
      %error.add_to_trace( {{ location }}.as(FileLocation))
    elsif ({{ location }}).is_a? Slang::Identifier
      %error.add_to_trace( {{ location }}.as(Slang::Identifier))
    end
    raise %error
  end
end
