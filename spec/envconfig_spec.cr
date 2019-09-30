require "./spec_helper"

class TestConfig
  EnvConfig.mapping({
    prefix:      {type: String, default: "l/", nilable: false},
    redis_host:  {type: String, default: "localhost", nilable: false},
    redis_port:  {type: Int32,  default: "6379", nilable: false},
    redis_pool:  {type: Int32,  default: "200", nilable: false},
    listen_port: {type: Int32,  default: "8087", nilable: false},
    default_url: {type: String, nilable: false},
    ssl_urls:    {type: Bool,   default: "false", nilable: false},
    unset_thing: {type: Int64,  nilable: true}
    }, "TEST"
  )
end

Spec2.describe EnvConfig do
  before do
    # Clean up the things we set in some of the tests. Otherwise, random
    # test failures, depending on test order.
    ENV.delete("TEST_DEFAULT_URL")
    ENV.delete("TEST_UNSET_THING")
  end

  let(:default_url) { "http://example.com/" }

  describe "when parsing the environment" do
    it "raises when nilable fields with no defaults are not available" do
      begin
        TestConfig.new()
      rescue e : KeyError
        expect(e.to_s).to eq("You must set a value for env var 'TEST_DEFAULT_URL'")
      end
    end

    it "does not raise when all nilable fields are available" do
      ENV["TEST_DEFAULT_URL"] = default_url
      TestConfig.new()
    end

    it "fills in the default vaules" do
      ENV["TEST_DEFAULT_URL"] = default_url
      config = TestConfig.new()

      expect(config.prefix).to eq ("l/")
      expect(config.redis_host).to eq ("localhost")
      expect(config.redis_port).to eq (6379)
      expect(config.redis_pool).to eq (200)
      expect(config.listen_port).to eq (8087)
      expect(config.ssl_urls).to be_false
    end

    it "doesn't complain when something is not set and is nilable" do
      ENV["TEST_DEFAULT_URL"] = default_url
      config = TestConfig.new()

      expect(config.unset_thing).to be_nil
    end

    it "raises when it can't convert a value properly" do
      ENV["TEST_DEFAULT_URL"] = default_url
      ENV["TEST_UNSET_THING"] = "asdf"
      begin
        config = TestConfig.new()
        expect(config.unset_thing).to be_nil
      rescue e : ArgumentError
        expect(e.to_s).to match(/Invalid Int64/)
      end
    end
  end
end
