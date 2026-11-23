# frozen_string_literal: true

# Ported from turndown-plugin-gfm by Dom Christie
# (https://github.com/mixmark-io/turndown-plugin-gfm), released under the
# MIT License. See LICENSE for the full notice.

module Turndown
  module Plugins
    module GFM
      HIGHLIGHT_REGEXP = /highlight-(?:text|source)-([a-z0-9]+)/
      ALIGN_MAP = {
        "left" => ":--",
        "right" => "--:",
        "center" => ":-:"
      }.freeze

      module_function

      def call(converter)
        converter.use([
          HighlightedCodeBlock,
          Strikethrough,
          Tables,
          TaskListItems
        ])
      end

      module Strikethrough
        module_function

        def call(converter)
          converter.add_rule(
            :strikethrough,
            filter: %w[del s strike],
            replacement: ->(content, _node, _options) { "~#{content}~" }
          )
        end
      end

      module TaskListItems
        module_function

        def call(converter)
          converter.add_rule(
            :task_list_items,
            filter: lambda do |node, _options|
              node.type == "checkbox" && node.parent_node&.node_name == "LI"
            end,
            replacement: ->(_content, node, _options) { "#{node.checked? ? '[x]' : '[ ]'} " }
          )
        end
      end

      module HighlightedCodeBlock
        module_function

        def call(converter)
          converter.add_rule(
            :highlighted_code_block,
            filter: lambda do |node, _options|
              first_child = node.first_child
              node.node_name == "DIV" &&
                node.class_name.match?(HIGHLIGHT_REGEXP) &&
                first_child &&
                first_child.node_name == "PRE"
            end,
            replacement: lambda do |_content, node, options|
              language = node.class_name[HIGHLIGHT_REGEXP, 1].to_s
              "\n\n#{options[:fence]}#{language}\n#{node.first_child.text_content}\n#{options[:fence]}\n\n"
            end
          )
        end
      end

      module Tables
        module_function

        def call(converter)
          converter.keep(lambda { |node, _options| node.node_name == "TABLE" && node.rows.none? { |row| heading_row?(row) } })

          converter.add_rule(
            :table_cell,
            filter: %w[th td],
            replacement: ->(content, node, _options) { cell(content, node) }
          )

          converter.add_rule(
            :table_row,
            filter: "tr",
            replacement: lambda do |content, node, _options|
              next "" if empty_row?(node)

              border_cells = String.new

              if heading_row?(node)
                node.child_nodes.each do |child|
                  next unless %w[TH TD].include?(child.node_name)

                  border = ALIGN_MAP.fetch(child.get_attribute("align").to_s.downcase, "---")
                  border_cells << cell(border, child)
                end
              end

              "\n#{content}#{border_cells.empty? ? '' : "\n#{border_cells}"}"
            end
          )

          converter.add_rule(
            :table,
            filter: lambda do |node, _options|
              node.node_name == "TABLE" && node.rows.any? { |row| heading_row?(row) }
            end,
            replacement: lambda do |content, _node, _options|
              "\n\n#{content.sub("\n\n", "\n")}\n\n"
            end
          )

          converter.add_rule(
            :table_section,
            filter: %w[thead tbody tfoot],
            replacement: ->(content, _node, _options) { content }
          )
        end

        def heading_row?(row)
          return false unless row

          parent = row.parent_node
          cells = row.child_nodes.select(&:element?)
          return false if cells.empty?

          if parent&.node_name == "THEAD"
            cells.any? { |child| !child.text_content.empty? }
          else
            return false unless cells.all? { |child| child.node_name == "TH" }

            parent &&
              row.same_node?(parent.first_child || row) &&
              (parent.node_name == "TABLE" || first_tbody?(parent))
          end
        end

        # <caption> and <colgroup> may precede the first <tbody> without
        # contributing rows, so they are skipped.
        def first_tbody?(element)
          return false unless element.node_name == "TBODY"

          previous_sibling = element.raw.previous_element
          while previous_sibling && %w[caption colgroup].include?(previous_sibling.name.downcase)
            previous_sibling = previous_sibling.previous_element
          end

          previous_sibling.nil? ||
            (
              previous_sibling.name.casecmp("thead").zero? &&
              previous_sibling.text.match?(/\A\s*\z/)
            )
        end

        def cell(content, node)
          index = node.parent_node.children.find_index { |child| child.same_node?(node) } || 0
          prefix = index.zero? ? "| " : " "
          "#{prefix}#{content} |"
        end

        def empty_row?(row)
          return false if heading_row?(row)

          cells = row.child_nodes.select(&:element?)
          cells.any? && cells.all? { |cell| cell.text_content.empty? }
        end
      end
    end
  end
end
