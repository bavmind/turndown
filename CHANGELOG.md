# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Converter#add_transform` — registers a callable run against the parsed tree
  before any rule is applied, receiving `(root, options)`. Rules are matched
  depth-first, so restructuring a subtree is not possible from a replacement.
  Registering no transforms leaves conversion byte-identical.
- `Turndown::Plugins::TableGrid`, a Ruby-side extension with no upstream
  equivalent. It resolves cells onto a logical grid and pads rows to the table's
  full width, so `colspan`/`rowspan` no longer shift following cells into the
  wrong column. It renders through the GFM table rules and registers them
  itself, so it works without loading the rest of GFM.
- `table_spans` option — `:blank` (default) leaves covered positions empty;
  `:flatten` repeats the cell into every position it covers, so each row can be
  read on its own; `:multimarkdown` emits `^^` for row spans and trailing pipes
  for column spans, preserving the merge for readers that understand it.
- `headerless_tables` option — `:keep` (default) preserves upstream behavior of
  leaving headerless tables as raw HTML; `:blank_header` and `:first_row_header`
  convert them.

Both options require `TableGrid`; they are ignored by the GFM plugin alone.
Upstream fixture output is unchanged unless the plugin is loaded.

## [1.0.0] - 2026-08-08

Initial public release.

Requires Ruby >= 3.3. The floor tracks Ruby's own maintained branches rather
than a fixed version, so expect it to move as branches reach end of life.

### Added

- `Turndown::Converter` — a Nokogiri-backed HTML to Markdown converter ported
  from [Turndown](https://github.com/mixmark-io/turndown) `7.2.2`.
- Accepts HTML strings, Nokogiri element nodes, documents, and document
  fragments as input.
- Converter API: `#convert`, `#use`, `#add_rule`, `#keep`, `#remove`, `#escape`.
- Options with symbol keys in snake_case: `heading_style`, `hr`,
  `bullet_list_marker`, `code_block_style`, `fence`, `em_delimiter`,
  `strong_delimiter`, `link_style`, `link_reference_style`, `br`,
  `preformatted_code`, `blank_replacement`, `keep_replacement`,
  `default_replacement`.
- `Turndown::Plugins::GFM`, ported from
  [turndown-plugin-gfm](https://github.com/mixmark-io/turndown-plugin-gfm),
  with `Strikethrough`, `Tables`, `TaskListItems`, and `HighlightedCodeBlock`
  available individually.
- Custom rule and plugin support via any Ruby callable.
- Parity test suite running the upstream fixture corpus: 149 core fixtures and
  18 GFM fixtures.

[Unreleased]: https://github.com/bavmind/turndown/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/bavmind/turndown/releases/tag/v1.0.0
