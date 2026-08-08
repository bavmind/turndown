# frozen_string_literal: true

module FixtureLoader
  Fixture = Struct.new(:name, :input, :expected, :options, keyword_init: true)

  module_function

  def load(path)
    document = Nokogiri::HTML5::Document.parse(File.read(path, encoding: "UTF-8"))

    document.css(".case").map do |fixture|
      Fixture.new(
        name: fixture["data-name"],
        input: fixture.at_xpath('./div[@class="input"]').inner_html,
        expected: normalize_newlines(fixture.at_xpath('./pre[@class="expected"]').text),
        options: parse_options(fixture["data-options"])
      )
    end
  end

  def parse_options(raw_options)
    return {} if raw_options.to_s.empty?

    JSON.parse(raw_options).each_with_object({}) do |(key, value), options|
      options[Turndown::Utilities.camel_to_snake(key).to_sym] = value
    end
  end

  def normalize_newlines(string)
    string.gsub(/\r\n?/, "\n")
  end

  def test_name(prefix, name, index)
    slug = name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "")
    "#{prefix}_#{index}_#{slug}"
  end
end
