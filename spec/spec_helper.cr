require "spectator"
require "../src/envconfig"

Spectator.configure do |config|
  config.add_formatter Spectator::Formatting::HTMLFormatter.new
end
