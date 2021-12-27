# envconfig is an environment variable configuration mapper for Crystal. It
# uses syntax similar to JSON, YAML, and DB shards to map environment variables
# to a Crystal class. It additionally contains a configuration printer for
# application startup so that the config values that were interpolated can be
# displayed for debugging purposes.
#
# Macros are used to handle most of the important operations, similary to JSON,
# YAML, and DB mapping macros. This `EnvConfig` module contains all the macros
# and necessary functions to operate the library.
#
# The normal entrypoint for code is the `mapping` macro.
module EnvConfig
  VERSION = "0.1.0"

  # Fetch a key from the environment, or set a default if the key is missing.
  # If the default is nil, abort and request that the required key be set.
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

  # Determine the lookup key for this field in the environment consists of an
  # upper case of the field name prefixed by any specified prefix.
  def key_for(name)
    if get_env_prefix().empty?
      name.to_s.upcase
    else
      "#{get_env_prefix()}_#{name}".upcase
    end
  end

  def format(name, value)
    @out_io.puts "  * " + "%20s" % "#{name}: " + value
  end

  def header
    @out_io.puts "Settings " + "-"*45
  end

  def footer
    @out_io.puts "" + "-"*55
  end

  # Mapping does most of the work figuring out how to configure and set the
  # properties. It is to be called from inside a class you define in your code.
  # The resultant properties are turned into properties on the class. Example
  # Usage:
  #
  # ```
  # class Config
  #   EnvConfig.mapping({
  #     prefix:      {type: String, default: "l/", nilable: false},
  #     redis_host:  {type: String, default: "localhost", nilable: false},
  #     redis_port:  {type: Int32, default: "6379", nilable: false},
  #     redis_pool:  {type: Int32, default: "200", nilable: false},
  #     listen_port: {type: Int32, default: "8087", nilable: false},
  #     default_url: {type: String, nilable: false},
  #     ssl_urls:    {type: Bool, default: "false", nilable: false},
  #   }, "CHOP"
  #   )
  # end
  # ```
  macro mapping(properties, prefix = "")
    include EnvConfig

    setter out_io : IO

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

      @out_io = STDOUT
    end

    # help generates help output suitable for use as a CLI help output. Useful
    # for apps that are callable on the CLI and want to provide help.
    def help
      @out_io.puts
      footer
      @out_io.puts "Usage:\n"
      @out_io.puts "  The following vars apply. Types and defaults shown:"
      @out_io.puts

      {% for key, v in properties %}
        type = {{ v[:type].stringify }}

        key = key_for("{{key}}")
        desc = {{v[:default]}}
        nilable = {{v[:nilable]}}

        unless desc
          if !nilable
            desc = "*REQUIRED*"
          else
            desc = "*NIL*"
          end
        end

        @out_io.puts " * #{key} (#{type}) - #{desc}"
      {% end %}
      footer
    end

    # print_config will print out a little formatted dump of all the settings
    # and their current value. Ideal for application startup.
    def print_config
      header

      {% for key, _v in properties %}
        format("{{key}}", @{{key}}.inspect)
      {% end %}

      footer
    end

    # print_config can optionally take a block that is used to obfuscate
    # strings that should not be displayed in the config output. This block
    # will be passed the key and the value and is expected to return the output
    # string to display.
    def print_config(&block : String, Int32 | Int64 | Float32 | Float64 | Bool | String | Nil -> String)
      header

      {% for key, _v in properties %}
        value = block.call("{{key}}", @{{key}})
        format("{{key}}", value)
      {% end %}

      footer
    end
  end

  # This is a convenience method to allow invoking `EnvVar.mapping`
  # with named arguments instead of with a hash/named-tuple literal.
  macro mapping(**properties)
    ::EnvConfig.mapping({{properties}})
  end
end
