require "./spec_helper"

class TestConfig
  EnvConfig.mapping({
    prefix:      {type: String, default: "l/", nilable: false, help: "URL Prefix for redirects"},
    redis_host:  {type: String, default: "localhost", nilable: false, help: "Redis hostname"},
    redis_port:  {type: Int32, default: "6379", nilable: false, help: "Redis port"},
    redis_pool:  {type: Int32, default: "200", nilable: false, help: "Redis pool size"},
    listen_port: {type: Int32, default: "8087", nilable: false, help: "Port to listen on"},
    default_url: {type: String, nilable: false, help: "Default URL to send redirects to"},
    ssl_urls:    {type: Bool, default: "false", nilable: false, help: nil},
    unset_thing: {type: Int64, nilable: true},
  }, "TEST"
  )
end

# There are two ways to define the mapping, this simply validates that the
# second method is working.
class SimpleConfig
  EnvConfig.mapping(
    name: {type: String, default: "beowulf", nilable: false, help: "The warrior's name"},
    is_awesome: {type: Bool, default: "true", nilable: false, help: "Whether they are awesome"}
  )
end

Spectator.describe EnvConfig do
  before_each do
    # Clean up the things we set in some of the tests. Otherwise, random
    # test failures, depending on test order.
    ENV.delete("TEST_DEFAULT_URL")
    ENV.delete("TEST_UNSET_THING")
  end

  let(:default_url) { "http://example.com/" }

  describe "when parsing the environment" do
    it "raises when nilable fields with no defaults are not available" do
      begin
        TestConfig.new
      rescue e : KeyError
        expect(e.to_s).to eq("You must set a value for env var 'TEST_DEFAULT_URL'")
      end
    end

    it "does not raise when all nilable fields are available" do
      ENV["TEST_DEFAULT_URL"] = default_url
      TestConfig.new
    end

    it "fills in the default vaules" do
      ENV["TEST_DEFAULT_URL"] = default_url
      config = TestConfig.new

      expect(config.prefix).to eq("l/")
      expect(config.redis_host).to eq("localhost")
      expect(config.redis_port).to eq(6379)
      expect(config.redis_pool).to eq(200)
      expect(config.listen_port).to eq(8087)
      expect(config.ssl_urls).to be_false
    end

    it "doesn't complain when something is not set and is nilable" do
      ENV["TEST_DEFAULT_URL"] = default_url
      config = TestConfig.new

      expect(config.unset_thing).to be_nil
    end

    it "raises when it can't convert a value properly" do
      ENV["TEST_DEFAULT_URL"] = default_url
      ENV["TEST_UNSET_THING"] = "asdf"
      begin
        config = TestConfig.new
        expect(config.unset_thing).to be_nil
      rescue e : ArgumentError
        expect(e.to_s).to match(/Invalid Int64/)
      end
    end
  end

  describe "when showing help()" do
    it "properly outputs all the fields and help text" do
      output = IO::Memory.new
      TestConfig.help(output)

      expect(output.to_s).to match(/TEST_PREFIX \(String\) - URL Prefix for redirects \[l\/\]/)
      expect(output.to_s).to match(/TEST_REDIS_HOST \(String\) - Redis hostname \[localhost\]/)
      expect(output.to_s).to match(/TEST_REDIS_PORT \(Int32\) -.*\[6379\]/)
      expect(output.to_s).to match(/TEST_REDIS_POOL \(Int32\) -.*\[200\]/)
      expect(output.to_s).to match(/TEST_DEFAULT_URL \(String\) -.*\[\*REQUIRED\*\]/)
      expect(output.to_s).to match(/TEST_LISTEN_PORT \(Int32\) -.*\[8087\]/)
      expect(output.to_s).to match(/TEST_SSL_URLS \(Bool\) -.*\[false\]/)
    end

    it "shows help properly for the second mapping() definition" do
      output = IO::Memory.new
      SimpleConfig.help(output)

      expect(output.to_s).to match(/ IS_AWESOME \(Bool\)/)
      expect(output.to_s).to match(/ NAME \(String\)/)
    end
  end

  describe "when printing output" do
    it "works fine without a block" do
      output = IO::Memory.new

      ENV["TEST_DEFAULT_URL"] = default_url
      config = TestConfig.new
      config.out_io = output
      config.print_config

      expect(output.to_s).to match(/^Settings ---/)
      expect(output.to_s.size).to eq(366)
    end

    it "calls an obfuscator block if there is one" do
      ENV["TEST_DEFAULT_URL"] = default_url

      output = IO::Memory.new

      config = TestConfig.new
      config.out_io = output
      config.print_config do |key, val|
        if key =~ /redis/
          "xx#{val}xx"
        else
          val.inspect
        end
      end

      expect(output.to_s).to match(/redis_host: xxlocalhostxx/)
      expect(output.to_s).to match(/redis_port: xx6379xx/)
      expect(output.to_s).to match(/redis_pool: xx200xx/)
      expect(output.to_s.size).to eq(376)
    end
  end
end
