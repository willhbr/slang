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

macro check_type(var, type, message=nil)
  {% if message == nil %}
    {% message = "Must be of type #{ type }" %}
  {% end %}
  unless ({{ var }}).is_a? {{ type }}
    error!(
      {% if message == nil %}
        "Must be of type #{ {{ type }}.type.name }, not #{ {{ var }}.type }"
      {% else %}
        {{ message }} + ", got #{ {{ var }}.type.name }"
      {% end %}
      {% if type == Slang::Identifier %}
        , {{ var }}
      {% end %}
    )
  else
    {{ var }}
  end
end
