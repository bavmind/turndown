# frozen_string_literal: true

require_relative "test_helper"

class GfmFixturesTest < Minitest::Test
  FixtureLoader.load(File.expand_path("fixtures/upstream/turndown_gfm.html", __dir__)).each_with_index do |fixture, index|
    define_method(FixtureLoader.test_name("test_gfm_fixture", fixture.name, index)) do
      converter = Turndown::Converter.new(fixture.options)
      converter.use(Turndown::Plugins::GFM)

      assert_equal fixture.expected, converter.convert(fixture.input)
    end
  end
end
