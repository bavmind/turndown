# frozen_string_literal: true

require_relative "test_helper"

class TurndownFixturesTest < Minitest::Test
  FixtureLoader.load(File.expand_path("fixtures/upstream/turndown_core.html", __dir__)).each_with_index do |fixture, index|
    define_method(FixtureLoader.test_name("test_core_fixture", fixture.name, index)) do
      converter = Turndown::Converter.new(fixture.options)
      assert_equal fixture.expected, converter.convert(fixture.input)
    end
  end
end
