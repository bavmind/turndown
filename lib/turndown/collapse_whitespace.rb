# frozen_string_literal: true

# Adapted, by way of Turndown, from collapse-whitespace by Luc Thevenard.
#
# Copyright (c) 2014 Luc Thevenard <lucthevenard@gmail.com>
# Released under the MIT License. See LICENSE for the full notice.

module Turndown
  module CollapseWhitespace
    module_function

    def call(element:, is_block:, is_void:, is_pre: nil)
      is_pre ||= ->(node) { node.element? && node.name.casecmp("pre").zero? }
      return if element.children.empty?
      return if is_pre.call(element)

      prev_text = nil
      keep_leading_ws = false

      prev = nil
      node = next_node(prev, element, is_pre)

      until node == element
        if node.text? || node.cdata?
          text = node.content.gsub(/[ \r\n\t]+/, " ")

          if (!prev_text || prev_text.content.end_with?(" ")) &&
             !keep_leading_ws &&
             text.start_with?(" ")
            text = text[1..] || ""
          end

          if text.empty?
            node = remove(node)
            next
          end

          node.content = text
          prev_text = node
        elsif node.element?
          if is_block.call(Node.new(node, {})) || node.name.casecmp("br").zero?
            prev_text.content = prev_text.content.sub(/ $/, "") if prev_text
            prev_text = nil
            keep_leading_ws = false
          elsif is_void.call(Node.new(node, {})) || is_pre.call(node)
            prev_text = nil
            keep_leading_ws = true
          elsif prev_text
            keep_leading_ws = false
          end
        else
          node = remove(node)
          next
        end

        next_candidate = next_node(prev, node, is_pre)
        prev = node
        node = next_candidate
      end

      if prev_text
        prev_text.content = prev_text.content.sub(/ $/, "")
        prev_text.remove if prev_text.content.empty?
      end
    end

    def remove(node)
      next_node = node.next_sibling || node.parent
      node.remove
      next_node
    end

    def next_node(prev, current, is_pre)
      if (prev && prev.parent == current) || is_pre.call(current)
        current.next_sibling || current.parent
      else
        current.children.first || current.next_sibling || current.parent
      end
    end
  end
end
