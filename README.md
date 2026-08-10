# Turndown

[![Gem Version](https://img.shields.io/gem/v/turndown.svg)](https://rubygems.org/gems/turndown)
[![CI](https://github.com/bavmind/turndown/actions/workflows/ci.yml/badge.svg)](https://github.com/bavmind/turndown/actions/workflows/ci.yml)

Convert HTML to Markdown in Ruby.

```ruby
Turndown::Converter.new.convert("<h1>Hello world</h1>")
# => "Hello world\n==========="
```

> **This is a Ruby port of [Turndown](https://github.com/mixmark-io/turndown) by Dom Christie.**
> It is an unofficial port, not affiliated with or endorsed by the upstream
> JavaScript project. Conversion behavior, rule semantics, and the test fixture
> corpus are derived from upstream Turndown `7.2.2` and
> [turndown-plugin-gfm](https://github.com/mixmark-io/turndown-plugin-gfm).
> See [Credits](#credits).

## Requirements

- Ruby >= 3.3 (tracks Ruby's own maintained branches)
- Nokogiri >= 1.16

## Installation

Add it to your Gemfile:

```ruby
gem "turndown"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install turndown
```

## Usage

### Convert an HTML string

```ruby
require "turndown"

converter = Turndown::Converter.new
markdown = converter.convert("<h1>Hello world</h1>")

puts markdown
# Hello world
# ===========
```

### Convert a Nokogiri node or fragment

```ruby
require "nokogiri"
require "turndown"

fragment = Nokogiri::HTML5::DocumentFragment.parse("<p>Hello</p><p>world</p>")
converter = Turndown::Converter.new

puts converter.convert(fragment)
# Hello
#
# world
```

Accepted inputs:

- HTML `String`
- `Nokogiri` element nodes
- `Nokogiri` documents
- `Nokogiri` document fragments

## API

- `Turndown::Converter.new(options = {})`
- `converter.convert(input)`
- `converter.use(plugin_or_plugins)`
- `converter.add_rule(name, filter:, replacement:, append: nil)`
- `converter.add_transform(callable = nil, &block)`
- `converter.keep(filter)`
- `converter.remove(filter)`
- `converter.escape(string)`

Every method except `convert` and `escape` returns the converter, so calls chain.

## Options

Options use symbol keys and snake_case names.

| Option | Default | Notes |
| :-- | :-- | :-- |
| `heading_style` | `"setext"` | or `"atx"` |
| `hr` | `"* * *"` | |
| `bullet_list_marker` | `"*"` | or `"-"`, `"+"` |
| `code_block_style` | `"indented"` | or `"fenced"` |
| `fence` | ` "```" ` | or `"~~~"` |
| `em_delimiter` | `"_"` | or `"*"` |
| `strong_delimiter` | `"**"` | or `"__"` |
| `link_style` | `"inlined"` | or `"referenced"` |
| `link_reference_style` | `"full"` | or `"collapsed"`, `"shortcut"` |
| `br` | `"  "` | |
| `preformatted_code` | `false` | |
| `blank_replacement` | proc | |
| `keep_replacement` | proc | |
| `default_replacement` | proc | |

```ruby
converter = Turndown::Converter.new(
  heading_style: "atx",
  code_block_style: "fenced",
  fence: "~~~",
  bullet_list_marker: "-"
)
```

## Plugins

GFM support ships in the same gem under `Turndown::Plugins::GFM`.

```ruby
require "turndown"

converter = Turndown::Converter.new
converter.use(Turndown::Plugins::GFM)

puts converter.convert("<strike>Hello</strike>")
# ~Hello~
```

Individual plugins can be used on their own:

- `Turndown::Plugins::GFM` — all of the below
- `Turndown::Plugins::GFM::Strikethrough`
- `Turndown::Plugins::GFM::Tables`
- `Turndown::Plugins::GFM::TaskListItems`
- `Turndown::Plugins::GFM::HighlightedCodeBlock`

Beyond the upstream port, `Turndown::Plugins::TableGrid` adds merged-cell
and headerless-table support — see [Table grid](#table-grid).

## Table grid

`Turndown::Plugins::TableGrid` handles merged cells and headerless tables.
**This is a Ruby-side extension — it has no upstream equivalent.**

It renders through the GFM table rules and registers them for you, so it works
on its own:

```ruby
converter = Turndown::Converter.new(
  table_spans: :multimarkdown,
  headerless_tables: :first_row_header
)
converter.use(Turndown::Plugins::TableGrid)
```

If you want the rest of GFM as well, load it **first** — later rules take
precedence, so `TableGrid` has to come last:

```ruby
converter.use([Turndown::Plugins::GFM, Turndown::Plugins::TableGrid])
```

### Why it exists

The GFM plugin treats each `<th>`/`<td>` as exactly one Markdown cell, so a
`colspan` or `rowspan` silently shifts every following cell into the wrong
column:

```ruby
# GFM alone
"| Name | Email |\n| --- | --- |\n| Ada | a@x.com |\n| a@work.com |"
#                                                    ^ landed under Name
```

Loading `TableGrid` resolves cells onto a logical grid and pads every row
to the table's full width, so a value always sits in its true column.

### `table_spans`

Markdown has no merged cells, so the option picks how they are represented.

| Value | Behavior |
| :-- | :-- |
| `:blank` (default) | Content sits in its true column; covered positions are left empty. Valid GFM, loses the merge. |
| `:flatten` | The cell repeats into every position it covers. Valid GFM, redundant but self-contained. |
| `:multimarkdown` | Row spans emit `^^`, column spans emit trailing pipes. Lossless, but needs a [MultiMarkdown](https://fletcher.github.io/MultiMarkdown-6/syntax.html#tables)-aware reader. |

Given a `rowspan="2"` on `Ada`:

```
:blank                :flatten              :multimarkdown
| Name | Email |      | Name | Email |      | Name | Email |
| --- | --- |         | --- | --- |         | --- | --- |
| Ada | a@x.com |     | Ada | a@x.com |     | Ada | a@x.com |
|  | a@work.com |     | Ada | a@work.com |  | ^^ | a@work.com |
```

Choosing between them:

- **`:flatten`** if rows are extracted independently — each row carries its own
  context, so a row lifted out of the table still makes sense on its own.
- **`:multimarkdown`** if the merge itself matters and you control the reader.
  Note that a row containing `^^` refers to the row above it, so it cannot be
  read in isolation.
- **`:blank`** if you want neither invented duplicates nor non-standard syntax.

They aren't exclusive. Converting the same source twice — `:flatten` for
indexing, `:multimarkdown` for display — costs one extra pass and avoids
parsing Markdown back into a grid later.

### `headerless_tables`

GFM requires a header row, so the GFM plugin keeps headerless tables as raw
HTML. This option converts them instead.

| Value | Behavior |
| :-- | :-- |
| `:keep` (default) | Leave as raw HTML — upstream behavior. |
| `:blank_header` | Convert, emitting an empty header row. |
| `:first_row_header` | Convert, promoting the first row to the header. |

`:first_row_header` reads better, but it *asserts* that row one contains column
names. For a key/value table like `Office | Berlin`, that makes "Berlin" a
column label. Prefer `:blank_header` when you don't know the shape of the input,
and `:first_row_header` only for sources you control.

Tables that already have a header row are unaffected by this option.

## Transforms

Rules are matched depth-first, so by the time a rule runs, its children are
already converted strings. A plugin that needs to restructure a subtree has to
do it beforehand, via a transform:

```ruby
converter.add_transform do |root, options|
  root.css("aside").each { |node| node.name = "blockquote" }
end
```

Transforms receive the parsed tree and the options hash, and run in
registration order before any rule. `TableGrid` uses one to build its
table grid.

## Custom rules

Rules stay close to upstream Turndown, but use Ruby callables.

### Add a rule

```ruby
converter = Turndown::Converter.new

converter.add_rule(
  :strikethrough,
  filter: %w[del s strike],
  replacement: ->(content, _node, _options) { "~~#{content}~~" }
)
```

`filter` may be:

- a tag name string
- a tag name symbol
- an array of tag names
- a `Proc` receiving `(node, options)`

### Keep raw HTML

```ruby
converter.keep(%w[del ins])
```

### Remove nodes

```ruby
converter.remove("script")
```

### Write a plugin

Plugins are callables that receive the converter instance:

```ruby
MyPlugin = lambda do |converter|
  converter.add_rule(
    :callout,
    filter: "aside",
    replacement: ->(content, _node, _options) { "\n\n> #{content}\n\n" }
  )
end

converter.use(MyPlugin)
```

## Escaping

`converter.escape` exposes the Markdown escaping behavior used internally:

```ruby
converter = Turndown::Converter.new
converter.escape("`not code`")
# => "\\`not code\\`"
```

## Differences from the JavaScript version

- The API is Ruby-first. There is no `TurndownService#turndown` alias — use
  `Turndown::Converter#convert`.
- Options are symbol keys in snake_case (`heading_style`), not camelCase
  (`headingStyle`).
- Rules and plugins are Ruby callables (`Proc`, `lambda`, or anything responding
  to `#call`) rather than JavaScript functions.
- Nokogiri is the only supported parser backend.

## Parity with upstream

The suite runs the upstream fixture corpus directly:

- 149 upstream Turndown core fixtures
- 18 upstream turndown-plugin-gfm fixtures
- 10 Ruby-specific tests for Nokogiri inputs, rule registration, plugins, and
  option handling

The vendored fixture files live under `test/fixtures/upstream/`.

## Development

```bash
bundle install
bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/bavmind/turndown>. See [CONTRIBUTING.md](CONTRIBUTING.md).

Because this is a port, behavior changes should generally track upstream
Turndown. If you find a case where this gem and upstream Turndown disagree,
that is a bug — please include the HTML input and both outputs.

## Credits

This gem exists because of the work of others:

- **[Turndown](https://github.com/mixmark-io/turndown)** by
  **[Dom Christie](https://github.com/domchristie)** — the original project this
  gem ports. Its conversion rules, behavior, and fixture corpus are the
  reference implementation here.
- **[turndown-plugin-gfm](https://github.com/mixmark-io/turndown-plugin-gfm)**,
  also by Dom Christie, is the source of the bundled GFM plugin behavior.
- **[collapse-whitespace](https://github.com/lucthev/collapse-whitespace)** by
  **[Luc Thevenard](https://github.com/lucthev)** — Turndown's whitespace
  collapsing logic is adapted from it, and this port follows that behavior.

All three are MIT licensed. Their copyright notices are retained in
[LICENSE](LICENSE).

## License

MIT © 2026 Devran Cosmo Uenal. Portions © 2017 Dom Christie and
© 2014 Luc Thevenard. See [LICENSE](LICENSE).
