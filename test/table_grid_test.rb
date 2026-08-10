# frozen_string_literal: true

require_relative "test_helper"

class TableGridTest < Minitest::Test
  def convert(html, options = {})
    Turndown::Converter
      .new(options)
      .use([Turndown::Plugins::GFM, Turndown::Plugins::TableGrid])
      .convert(html)
  end

  def gfm_only(html, options = {})
    Turndown::Converter.new(options).use(Turndown::Plugins::GFM).convert(html)
  end

  def table(body)
    "<table>#{body}</table>"
  end

  def test_colspan_in_heading_cell_pads_columns_when_blank
    html = table('<thead><tr><th colspan="2">Contact</th></tr></thead>' \
                 "<tbody><tr><td>Email</td><td>Phone</td></tr></tbody>")

    assert_equal "| Contact |  |\n| --- | --- |\n| Email | Phone |", convert(html)
  end

  def test_colspan_in_heading_cell_widens_cell_when_multimarkdown
    html = table('<thead><tr><th colspan="2">Contact</th></tr></thead>' \
                 "<tbody><tr><td>Email</td><td>Phone</td></tr></tbody>")

    assert_equal "| Contact ||\n| --- | --- |\n| Email | Phone |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_colspan_in_body_cell
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td colspan="2">wide</td></tr></tbody>')

    assert_equal "| A | B |\n| --- | --- |\n| wide ||",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_rowspan_in_first_column_keeps_following_cells_in_place
    html = table("<thead><tr><th>Name</th><th>Email</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">Ada</td><td>a@x.com</td></tr>' \
                 "<tr><td>a@work.com</td></tr></tbody>")

    assert_equal "| Name | Email |\n| --- | --- |\n| Ada | a@x.com |\n| ^^ | a@work.com |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_rowspan_in_middle_column
    html = table("<thead><tr><th>Name</th><th>Status</th><th>Note</th></tr></thead>" \
                 '<tbody><tr><td>Ada</td><td rowspan="2">Active</td><td>One</td></tr>' \
                 "<tr><td>Grace</td><td>Two</td></tr></tbody>")

    assert_equal "| Name | Status | Note |\n| --- | --- | --- |\n" \
                 "| Ada | Active | One |\n| Grace | ^^ | Two |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_rowspan_leaves_column_empty_when_blank
    html = table("<thead><tr><th>Name</th><th>Email</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">Ada</td><td>a@x.com</td></tr>' \
                 "<tr><td>a@work.com</td></tr></tbody>")

    assert_equal "| Name | Email |\n| --- | --- |\n| Ada | a@x.com |\n|  | a@work.com |",
                 convert(html)
  end

  def test_multiple_simultaneous_row_spans
    html = table("<thead><tr><th>A</th><th>B</th><th>C</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">x</td><td rowspan="2">y</td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B | C |\n| --- | --- | --- |\n| x | y | 1 |\n| ^^ | ^^ | 2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_rowspan_zero_spans_to_end_of_row_group
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="0">X</td><td>1</td></tr>' \
                 "<tr><td>2</td></tr><tr><td>3</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n| X | 1 |\n| ^^ | 2 |\n| ^^ | 3 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_rowspan_is_clamped_to_existing_rows
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="99">X</td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n| X | 1 |\n| ^^ | 2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_row_spans_do_not_cross_row_group_boundaries
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="5">X</td><td>1</td></tr></tbody>' \
                 "<tfoot><tr><td>f1</td><td>f2</td></tr></tfoot>")

    assert_equal "| A | B |\n| --- | --- |\n| X | 1 |\n| f1 | f2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_combined_rowspan_and_colspan
    html = table("<thead><tr><th>Name</th><th colspan=\"2\">Contact</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">Ada</td><td>Email</td><td>a@x.com</td></tr>' \
                 "<tr><td>Phone</td><td>123</td></tr></tbody>")

    assert_equal "| Name | Contact ||\n| --- | --- | --- |\n" \
                 "| Ada | Email | a@x.com |\n| ^^ | Phone | 123 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_cell_spanning_both_axes_carries_colspan_onto_the_marker
    html = table("<thead><tr><th>A</th><th>B</th><th>C</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2" colspan="2">wide</td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B | C |\n| --- | --- | --- |\n| wide || 1 |\n| ^^ || 2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_flatten_repeats_a_spanned_heading_across_its_columns
    html = table('<thead><tr><th colspan="2">Contact</th></tr></thead>' \
                 "<tbody><tr><td>Email</td><td>Phone</td></tr></tbody>")

    assert_equal "| Contact | Contact |\n| --- | --- |\n| Email | Phone |",
                 convert(html, table_spans: :flatten)
  end

  def test_flatten_repeats_a_row_spanning_cell_so_each_row_stands_alone
    html = table("<thead><tr><th>Name</th><th>Email</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">Ada</td><td>a@x.com</td></tr>' \
                 "<tr><td>a@work.com</td></tr></tbody>")

    assert_equal "| Name | Email |\n| --- | --- |\n| Ada | a@x.com |\n| Ada | a@work.com |",
                 convert(html, table_spans: :flatten)
  end

  def test_flatten_combined_rowspan_and_colspan
    html = table('<thead><tr><th>Name</th><th colspan="2">Contact</th></tr></thead>' \
                 '<tbody><tr><td rowspan="2">Ada</td><td>Email</td><td>a@x.com</td></tr>' \
                 "<tr><td>Phone</td><td>123</td></tr></tbody>")

    assert_equal "| Name | Contact | Contact |\n| --- | --- | --- |\n" \
                 "| Ada | Email | a@x.com |\n| Ada | Phone | 123 |",
                 convert(html, table_spans: :flatten)
  end

  def test_flatten_fills_every_position_a_cell_covers_on_both_axes
    html = table("<thead><tr><th>A</th><th>B</th><th>C</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2" colspan="2">wide</td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B | C |\n| --- | --- | --- |\n" \
                 "| wide | wide | 1 |\n| wide | wide | 2 |",
                 convert(html, table_spans: :flatten)
  end

  def test_flatten_repeats_converted_inline_markdown
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2"><strong>bold</strong> ' \
                 '<a href="http://x.com">link</a></td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n" \
                 "| **bold** [link](http://x.com) | 1 |\n" \
                 "| **bold** [link](http://x.com) | 2 |",
                 convert(html, table_spans: :flatten)
  end

  def test_invalid_span_values_are_treated_as_one
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td colspan="">x</td><td rowspan="-3">y</td></tr>' \
                 '<tr><td colspan="abc">z</td><td colspan="0">w</td></tr></tbody>')

    assert_equal "| A | B |\n| --- | --- |\n| x | y |\n| z | w |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_short_rows_are_padded_to_table_width
    html = table("<thead><tr><th>A</th><th>B</th><th>C</th></tr></thead>" \
                 "<tbody><tr><td>1</td></tr></tbody>")

    assert_equal "| A | B | C |\n| --- | --- | --- |\n| 1 |  |  |", convert(html)
  end

  def test_multiple_tbody_elements_are_resolved_independently
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">x</td><td>1</td></tr><tr><td>2</td></tr></tbody>' \
                 "<tbody><tr><td>y</td><td>3</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n| x | 1 |\n| ^^ | 2 |\n| y | 3 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_alignment_survives_a_spanned_heading
    html = table('<thead><tr><th align="right" colspan="2">N</th></tr></thead>' \
                 '<tbody><tr><td align="right">1</td><td align="center">2</td></tr></tbody>')

    assert_equal "| N ||\n| --: | --: |\n| 1 | 2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def test_inline_markdown_inside_spanned_cells
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2"><strong>bold</strong> and ' \
                 '<a href="http://x.com">link</a></td><td>1</td></tr>' \
                 "<tr><td>2</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n" \
                 "| **bold** and [link](http://x.com) | 1 |\n| ^^ | 2 |",
                 convert(html, table_spans: :multimarkdown)
  end

  def headerless_html
    table("<tbody><tr><td>Office</td><td>Berlin</td></tr>" \
          "<tr><td>Hours</td><td>09-17</td></tr></tbody>")
  end

  def test_headerless_tables_stay_html_by_default
    assert_includes convert(headerless_html), "<table>"
  end

  def test_headerless_tables_with_blank_header
    assert_equal "|  |  |\n| --- | --- |\n| Office | Berlin |\n| Hours | 09-17 |",
                 convert(headerless_html, headerless_tables: :blank_header)
  end

  def test_headerless_tables_promoting_the_first_row
    assert_equal "| Office | Berlin |\n| --- | --- |\n| Hours | 09-17 |",
                 convert(headerless_html, headerless_tables: :first_row_header)
  end

  def test_headerless_option_leaves_tables_that_already_have_a_header_alone
    html = table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
                 "<tbody><tr><td>1</td><td>2</td></tr></tbody>")

    assert_equal "| A | B |\n| --- | --- |\n| 1 | 2 |",
                 convert(html, headerless_tables: :first_row_header)
  end

  def test_unknown_span_strategy_raises
    error = assert_raises(ArgumentError) { convert("<table></table>", table_spans: :nope) }

    assert_match(/table_spans/, error.message)
  end

  def test_unknown_headerless_mode_raises
    error = assert_raises(ArgumentError) { convert("<table></table>", headerless_tables: :nope) }

    assert_match(/headerless_tables/, error.message)
  end

  def test_plugin_does_not_mutate_nokogiri_input
    fragment = Nokogiri::HTML5::DocumentFragment.parse(
      table("<thead><tr><th>A</th><th>B</th></tr></thead>" \
            '<tbody><tr><td rowspan="2">X</td><td>1</td></tr><tr><td>2</td></tr></tbody>')
    )
    original = fragment.to_html

    Turndown::Converter
      .new(table_spans: :multimarkdown)
      .use([Turndown::Plugins::GFM, Turndown::Plugins::TableGrid])
      .convert(fragment)

    assert_equal original, fragment.to_html
  end

  def test_gfm_alone_is_untouched_by_the_options
    html = table("<thead><tr><th colspan=\"2\">Contact</th></tr></thead>" \
                 "<tbody><tr><td>Email</td><td>Phone</td></tr></tbody>")

    assert_equal gfm_only(html), gfm_only(html, table_spans: :multimarkdown)
  end

  def test_works_without_loading_the_full_gfm_plugin
    html = table("<thead><tr><th>Name</th><th>Email</th></tr></thead>" \
                 '<tbody><tr><td rowspan="2">Ada</td><td>a@x.com</td></tr>' \
                 "<tr><td>a@work.com</td></tr></tbody>")

    output = Turndown::Converter
             .new(table_spans: :flatten)
             .use(Turndown::Plugins::TableGrid)
             .convert(html)

    assert_equal "| Name | Email |\n| --- | --- |\n| Ada | a@x.com |\n| Ada | a@work.com |", output
  end

  def test_standalone_use_does_not_register_the_other_gfm_rules
    converter = Turndown::Converter.new.use(Turndown::Plugins::TableGrid)

    assert_equal "x", converter.convert("<strike>x</strike>")
  end

  def test_only_call_is_public
    assert_equal [:call], Turndown::Plugins::TableGrid.singleton_methods - Module.methods
  end

  def test_add_transform_runs_before_rules
    converter = Turndown::Converter.new
    converter.add_transform { |root, _options| root.css("em").each { |node| node.name = "strong" } }

    assert_equal "**x**", converter.convert("<em>x</em>")
  end

  def test_add_transform_rejects_non_callables
    assert_raises(TypeError) { Turndown::Converter.new.add_transform(:not_callable) }
  end
end
