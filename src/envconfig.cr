# TODO: Write documentation for `Envconfig`
module EnvConfig
  VERSION = "0.1.0"

  # Fetch a key from the environment, or set a default if the key
  # is missing. If the default is nil, abort and request that the
  # required key be set.
  def get_env(key : String, default : String?, nilable : Bool) : String?
    ENV[key]
  rescue KeyError
    if default.nil? && !nilable
      raise KeyError.new("You must set a value for env var '#{key}'")
    else
      default
    end
  end

  # Convert string values to bools in a simplistic way.
  def to_bool(value) : Bool
    value == "true" || value[0].downcase == "t"
  end

  # Determine the lookup key for this field in the environment
  # consists of an upper case of the field name prefixed by any
  # specified prefix.
  def key_for(name)
    if get_env_prefix().empty?
      name.to_s.upcase
    else
      "#{get_env_prefix()}_#{name}".upcase
    end
  end

  # Mapping does most of the work figuring out how to configure
  # and set the properties.
  macro mapping(properties, prefix = "")
    include EnvConfig

    def get_env_prefix()
      "{{prefix.id}}"
    end

    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
    {% end %}

    {% for key, value in properties %}
      @{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }}

      {% if value[:setter] == nil ? true : value[:setter] %}
        def {{key.id}}=(_{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }})
          @{{key.id}} = _{{key.id}}
        end
      {% end %}

      {% if value[:getter] == nil ? true : value[:getter] %}
        def {{key.id}}
          @{{key.id}}
        end
      {% end %}
    {% end %}

    def initialize()
      {% for key, value in properties %}
        key = key_for("{{key}}")
        result = get_env(key, {{value[:default]}}, {{value[:nilable]}})

        {% type = value[:type].stringify %}

        {% if value[:nilable] %}
        if result == nil
            @{{key}} = nil
        else
        {% else %}
          begin
        {% end %}
          {% if type == "Int32" %}
            @{{key}} = result.not_nil!.to_i32
          {% elsif type == "Int64" %}
            @{{key}} = result.not_nil!.to_i64
          {% elsif type == "Float32" %}
            @{{key}} = result.not_nil!.to_f32
          {% elsif type == "Float64" %}
            @{{key}} = result.not_nil!.to_f
          {% elsif type == "Bool" %}
            @{{key}} = to_bool(result.not_nil!)
          {% else %}
            @{{key}} = result.not_nil!
          {% end %}
        end
      {% end %}
    end

    # print_config will print out a little formatted dump of all the
    # settings and their current value. Ideal for application startup.
    def print_config
      puts "Settings " + "-"*45
      {% for key, _v in properties %}
        format "{{key}}", @{{key}}
      {% end %}
      puts "" + "-"*55
    end
  end

  # This is a convenience method to allow invoking `EnvVar.mapping`
  # with named arguments instead of with a hash/named-tuple literal.
  macro mapping(**properties)
    ::EnvConfig.mapping({{properties}})
  end

  private def format(name, value)
    puts "  * " + "%20s" % "#{name}: " + value.inspect
  end
end
