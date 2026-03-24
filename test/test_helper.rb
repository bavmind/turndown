$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "json"
require "turndown"

require_relative "support/fixture_loader"
