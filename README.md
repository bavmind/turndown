# turndown-ruby

A Ruby port of [Turndown](https://github.com/mixmark-io/turndown) for converting HTML to Markdown.

This gem keeps one canonical Ruby API:

- `Turndown::Converter.new(options = {})`
- `converter.convert(input)`
- `converter.use(plugin_or_plugins)`
- `converter.add_rule(name, filter:, replacement:, append: nil)`
- `converter.keep(filter)`
- `converter.remove(filter)`
- `converter.escape(string)`

The implementation is Nokogiri-backed and currently targets upstream Turndown `7.2.2` behavior, plus the bundled GFM plugin fixture corpus.

## Installation

This repository includes a gemspec, but the README assumes local or git-based usage unless and until the gem is published.

```ruby
# Gemfile
gem "turndown-ruby", path: "/path/to/turndown-ruby"
```

Then:

```sh
bundle install
```

For development inside this repo:

```sh
bundle install
bundle exec rake test
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

## Options

Options use symbol keys and snake_case names:

| Option | Default |
| :-- | :-- |
| `heading_style` | `"setext"` |
| `hr` | `"* * *"` |
| `bullet_list_marker` | `"*"` |
| `code_block_style` | `"indented"` |
| `fence` | `"```"` |
| `em_delimiter` | `"_"` |
| `strong_delimiter` | `"**"` |
| `link_style` | `"inlined"` |
| `link_reference_style` | `"full"` |
| `br` | `"  "` |
| `preformatted_code` | `false` |
| `blank_replacement` | proc |
| `keep_replacement` | proc |
| `default_replacement` | proc |

Examples:

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

Available plugin entrypoints:

- `Turndown::Plugins::GFM`
- `Turndown::Plugins::GFM::Strikethrough`
- `Turndown::Plugins::GFM::Tables`
- `Turndown::Plugins::GFM::TaskListItems`
- `Turndown::Plugins::GFM::HighlightedCodeBlock`

## Custom Rules

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

### Plugin shape

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

## Compatibility Notes

- This gem intentionally exposes a Ruby-first API only. It does not provide a JS-style `TurndownService#turndown` alias.
- Nokogiri is the only parser backend in v1.
- HTML string parsing goes through a synthetic wrapper element to keep malformed-document handling consistent inside Nokogiri.
- Upstream parity fixtures are vendored locally under [`test/fixtures/upstream/`](test/fixtures/upstream/).

## Verification

The current implementation is verified against:

- 149 upstream core Turndown fixtures
- 18 upstream GFM fixtures
- Ruby-specific API tests for Nokogiri inputs, rule registration, plugins, and option behavior

Run the suite with:

```sh
bundle exec rake test
```

## Attribution

- [Turndown](https://github.com/mixmark-io/turndown) was created by Dom Christie. This gem is a Ruby port of that project’s behavior and fixture corpus.
- [turndown-plugin-gfm](https://github.com/mixmark-io/turndown-plugin-gfm) provides the upstream GFM plugin behavior mirrored here.
- Turndown’s whitespace collapsing logic is adapted upstream from Luc Thevenard’s `collapse-whitespace` project, and this Ruby port follows that behavior as part of the port.
- The vendored fixture files under [`test/fixtures/upstream/`](test/fixtures/upstream/) are retained as the parity corpus used by the test suite.
