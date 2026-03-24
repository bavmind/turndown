require_relative "test_helper"

class ConverterTest < Minitest::Test
  def test_convert_accepts_string_input
    converter = Turndown::Converter.new

    assert_equal "Hello", converter.convert("<p>Hello</p>")
  end

  def test_convert_accepts_nokogiri_fragment_input
    fragment = Nokogiri::HTML5::DocumentFragment.parse("<p>Hello</p><p>World</p>")
    converter = Turndown::Converter.new

    assert_equal "Hello\n\nWorld", converter.convert(fragment)
  end

  def test_convert_does_not_mutate_nokogiri_input
    fragment = Nokogiri::HTML5::DocumentFragment.parse("<pre><code>One<br>Two</code></pre>")
    original = fragment.to_html

    Turndown::Converter.new(code_block_style: "fenced").convert(fragment)

    assert_equal original, fragment.to_html
  end

  def test_invalid_input_raises_type_error
    converter = Turndown::Converter.new

    assert_raises(TypeError) { converter.convert(42) }
  end

  def test_add_rule_returns_converter_and_applies_before_commonmark
    converter = Turndown::Converter.new

    returned = converter.add_rule(
      :paragraph_override,
      filter: "p",
      replacement: ->(content, _node, _options) { "[#{content}]" }
    )

    assert_same converter, returned
    assert_equal "[Hello]", converter.convert("<p>Hello</p>")
  end

  def test_use_accepts_arrays_of_plugins
    plugin = lambda do |converter|
      converter.add_rule(
        :custom_span,
        filter: "span",
        replacement: ->(content, _node, _options) { "<<#{content}>>" }
      )
    end

    converter = Turndown::Converter.new
    returned = converter.use([plugin])

    assert_same converter, returned
    assert_equal "<<Hello>>", converter.convert("<span>Hello</span>")
  end

  def test_keep_beats_remove
    converter = Turndown::Converter.new
    converter.keep("del")
    converter.remove("del")

    assert_equal "Hello <del>world</del>", converter.convert("<p>Hello <del>world</del></p>")
  end

  def test_append_hooks_run_during_post_process
    converter = Turndown::Converter.new
    converter.add_rule(
      :span,
      filter: "span",
      replacement: ->(content, _node, _options) { content },
      append: ->(_options) { "\n\nFOOTER" }
    )

    assert_equal "Hello\n\nFOOTER", converter.convert("<span>Hello</span>")
  end

  def test_snake_case_options_map_to_behavior
    converter = Turndown::Converter.new(heading_style: "atx", code_block_style: "fenced")

    assert_equal "# Hello", converter.convert("<h1>Hello</h1>")
    assert_equal "````ruby\ndef hi\n```\n````", converter.convert('<pre><code class="language-ruby">def hi
```</code></pre>')
  end

  def test_escape_uses_markdown_escaping
    converter = Turndown::Converter.new

    assert_equal "\\_a\\_", converter.escape("_a_")
  end
end
