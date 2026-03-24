module Turndown
  class Node
    attr_reader :raw, :options

    def initialize(raw, options)
      @raw = raw
      @options = options
    end

    def node_name
      raw.name.to_s.upcase
    end

    def node_name_downcase
      raw.name.to_s.downcase
    end

    def node_type
      return 9 if raw.is_a?(Nokogiri::HTML5::Document) || raw.is_a?(Nokogiri::HTML4::Document)
      return 11 if raw.is_a?(Nokogiri::HTML5::DocumentFragment) || raw.is_a?(Nokogiri::XML::DocumentFragment)
      return 1 if raw.element?
      return 4 if raw.cdata?
      return 3 if raw.text?

      0
    end

    def text_node?
      node_type == 3 || node_type == 4
    end

    def element?
      node_type == 1
    end

    def document?
      node_type == 9
    end

    def document_fragment?
      node_type == 11
    end

    def block?
      Utilities.is_block?(self)
    end

    def void?
      Utilities.is_void?(self)
    end

    def meaningful_when_blank?
      Utilities.is_meaningful_when_blank?(self)
    end

    def code?
      node_name == "CODE" || parent_node&.code?
    end

    def blank?
      !void? &&
        !meaningful_when_blank? &&
        text_content.match?(/\A\s*\z/) &&
        !Utilities.has_void?(raw) &&
        !Utilities.has_meaningful_when_blank?(raw)
    end

    def flanking_whitespace
      return { leading: "", trailing: "" } if block? || (options[:preformatted_code] && code?)

      edges = edge_whitespace(text_content)
      if edges[:leading_ascii] != "" && flanked_by_whitespace?(:left)
        edges[:leading] = edges[:leading_non_ascii]
      end
      if edges[:trailing_ascii] != "" && flanked_by_whitespace?(:right)
        edges[:trailing] = edges[:trailing_non_ascii]
      end

      { leading: edges[:leading], trailing: edges[:trailing] }
    end

    def node_value
      raw.content
    end

    def text_content
      raw.text
    end

    def outer_html
      raw.to_html
    end

    def class_name
      get_attribute("class").to_s
    end

    def type
      get_attribute("type")
    end

    def checked?
      !get_attribute("checked").nil?
    end

    def get_attribute(name)
      raw[name]
    end

    def child_nodes
      raw.children.map { |child| self.class.new(child, options) }
    end

    def parent_node
      return nil unless raw.respond_to?(:parent) && raw.parent

      self.class.new(raw.parent, options)
    end

    def previous_sibling
      return nil unless raw.respond_to?(:previous_sibling) && raw.previous_sibling

      self.class.new(raw.previous_sibling, options)
    end

    def next_sibling
      return nil unless raw.respond_to?(:next_sibling) && raw.next_sibling

      self.class.new(raw.next_sibling, options)
    end

    def first_child
      child = raw.children.first
      return nil unless child

      self.class.new(child, options)
    end

    def last_element_child
      child = raw.element_children.last
      child && self.class.new(child, options)
    end

    def children
      raw.element_children.map { |child| self.class.new(child, options) }
    end

    def rows
      raw.css("tr").map { |row| self.class.new(row, options) }
    end

    def same_node?(other)
      raw == other.raw
    end

    def inspect
      "#<Turndown::Node #{node_name}>"
    end

    private

    def edge_whitespace(string)
      chars = string.chars
      ascii_whitespace = +""
      non_ascii_leading = +""
      index = 0

      while index < chars.length && ascii_whitespace?(chars[index])
        ascii_whitespace << chars[index]
        index += 1
      end

      while index < chars.length && whitespace?(chars[index])
        non_ascii_leading << chars[index]
        index += 1
      end

      if index == chars.length
        leading = ascii_whitespace + non_ascii_leading
        return {
          leading: leading,
          leading_ascii: ascii_whitespace,
          leading_non_ascii: non_ascii_leading,
          trailing: "",
          trailing_non_ascii: "",
          trailing_ascii: ""
        }
      end

      trailing_ascii = +""
      trailing_non_ascii = +""
      index = chars.length - 1

      while index >= 0 && ascii_whitespace?(chars[index])
        trailing_ascii.prepend(chars[index])
        index -= 1
      end

      while index >= 0 && whitespace?(chars[index])
        trailing_non_ascii.prepend(chars[index])
        index -= 1
      end

      {
        leading: ascii_whitespace + non_ascii_leading,
        leading_ascii: ascii_whitespace,
        leading_non_ascii: non_ascii_leading,
        trailing: trailing_non_ascii + trailing_ascii,
        trailing_non_ascii: trailing_non_ascii,
        trailing_ascii: trailing_ascii
      }
    end

    def ascii_whitespace?(char)
      [" ", "\t", "\r", "\n"].include?(char)
    end

    def whitespace?(char)
      char.match?(/[[:space:]]/)
    end

    def flanked_by_whitespace?(side)
      sibling, pattern =
        if side == :left
          [raw.previous_sibling, / $/]
        else
          [raw.next_sibling, /^ /]
        end

      return false unless sibling

      if sibling.text? || sibling.cdata?
        sibling.content.match?(pattern)
      elsif options[:preformatted_code] && sibling.element? && sibling.name.casecmp("code").zero?
        false
      elsif sibling.element? && !Utilities.is_block?(self.class.new(sibling, options))
        sibling.text.match?(pattern)
      else
        false
      end
    end
  end
end
