# frozen_string_literal: true

# Turndown converts HTML to Markdown.
#
# This is an unofficial Ruby port of Turndown by Dom Christie
# (https://github.com/mixmark-io/turndown), released under the MIT License.
# It is not affiliated with or endorsed by the upstream project.

require "nokogiri"

require_relative "turndown/version"
require_relative "turndown/utilities"
require_relative "turndown/rule"
require_relative "turndown/rules"
require_relative "turndown/node"
require_relative "turndown/collapse_whitespace"
require_relative "turndown/root_node"
require_relative "turndown/commonmark_rules"
require_relative "turndown/converter"
require_relative "turndown/plugins/gfm"
require_relative "turndown/plugins/table_grid"
