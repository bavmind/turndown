module Turndown
  class ReferenceLinkRule < Rule
    def initialize
      super(
        filter: lambda do |node, options|
          options[:link_style] == "referenced" &&
            node.node_name == "A" &&
            node.get_attribute("href")
        end,
        replacement: method(:replace),
        append: method(:append_references)
      )
      @references = []
    end

    private

    def replace(content, node, options)
      href = CommonMarkRules.escape_link_destination(node.get_attribute("href"))
      title = CommonMarkRules.clean_attribute(node.get_attribute("title"))
      title = %( "#{CommonMarkRules.escape_link_title(title)}") unless title.empty?

      case options[:link_reference_style]
      when "collapsed"
        replacement = "[#{content}][]"
        reference = "[#{content}]: #{href}#{title}"
      when "shortcut"
        replacement = "[#{content}]"
        reference = "[#{content}]: #{href}#{title}"
      else
        id = @references.length + 1
        replacement = "[#{content}][#{id}]"
        reference = "[#{id}]: #{href}#{title}"
      end

      @references << reference
      replacement
    end

    def append_references(_options)
      return "" if @references.empty?

      output = "\n\n#{@references.join("\n")}\n\n"
      @references = []
      output
    end
  end

  module CommonMarkRules
    module_function

    def build
      {
        paragraph: Rule.new(
          filter: "p",
          replacement: ->(content, _node, _options) { "\n\n#{content}\n\n" }
        ),
        line_break: Rule.new(
          filter: "br",
          replacement: ->(_content, _node, options) { "#{options[:br]}\n" }
        ),
        heading: Rule.new(
          filter: %w[h1 h2 h3 h4 h5 h6],
          replacement: lambda do |content, node, options|
            h_level = node.node_name_downcase[1].to_i

            if options[:heading_style] == "setext" && h_level < 3
              underline = Utilities.repeat(h_level == 1 ? "=" : "-", content.length)
              "\n\n#{content}\n#{underline}\n\n"
            else
              "\n\n#{Utilities.repeat('#', h_level)} #{content}\n\n"
            end
          end
        ),
        blockquote: Rule.new(
          filter: "blockquote",
          replacement: lambda do |content, _node, _options|
            content = Utilities.trim_newlines(content).gsub(/^/, "> ")
            "\n\n#{content}\n\n"
          end
        ),
        list: Rule.new(
          filter: %w[ul ol],
          replacement: lambda do |content, node, _options|
            parent = node.parent_node
            if parent&.node_name == "LI" && parent.last_element_child&.same_node?(node)
              "\n#{content}"
            else
              "\n\n#{content}\n\n"
            end
          end
        ),
        list_item: Rule.new(
          filter: "li",
          replacement: lambda do |content, node, options|
            prefix = "#{options[:bullet_list_marker]}   "
            parent = node.parent_node

            if parent&.node_name == "OL"
              start = parent.get_attribute("start")
              index = parent.children.find_index { |child| child.same_node?(node) } || 0
              prefix = "#{start ? start.to_i + index : index + 1}.  "
            end

            paragraph = content.end_with?("\n")
            content = Utilities.trim_newlines(content)
            content += "\n" if paragraph
            content = content.gsub(/\n/, "\n#{' ' * prefix.length}")
            "#{prefix}#{content}#{node.next_sibling ? "\n" : ""}"
          end
        ),
        indented_code_block: Rule.new(
          filter: lambda do |node, options|
            options[:code_block_style] == "indented" &&
              node.node_name == "PRE" &&
              node.first_child &&
              node.first_child.node_name == "CODE"
          end,
          replacement: lambda do |_content, node, _options|
            code = node.first_child.text_content.gsub("\n", "\n    ")
            "\n\n    #{code}\n\n"
          end
        ),
        fenced_code_block: Rule.new(
          filter: lambda do |node, options|
            options[:code_block_style] == "fenced" &&
              node.node_name == "PRE" &&
              node.first_child &&
              node.first_child.node_name == "CODE"
          end,
          replacement: lambda do |_content, node, options|
            class_name = node.first_child.get_attribute("class").to_s
            language = class_name[/language-(\S+)/, 1].to_s
            code = node.first_child.text_content
            fence_char = options[:fence][0]
            fence_size = 3

            code.scan(/^#{Regexp.escape(fence_char)}{3,}/).each do |match|
              fence_size = match.length + 1 if match.length >= fence_size
            end

            fence = Utilities.repeat(fence_char, fence_size)
            "\n\n#{fence}#{language}\n#{code.sub(/\n\z/, '')}\n#{fence}\n\n"
          end
        ),
        horizontal_rule: Rule.new(
          filter: "hr",
          replacement: ->(_content, _node, options) { "\n\n#{options[:hr]}\n\n" }
        ),
        inline_link: Rule.new(
          filter: lambda do |node, options|
            options[:link_style] == "inlined" &&
              node.node_name == "A" &&
              node.get_attribute("href")
          end,
          replacement: lambda do |content, node, _options|
            href = escape_link_destination(node.get_attribute("href"))
            title = escape_link_title(clean_attribute(node.get_attribute("title")))
            title_part = title.empty? ? "" : %( "#{title}")
            "[#{content}](#{href}#{title_part})"
          end
        ),
        reference_link: ReferenceLinkRule.new,
        emphasis: Rule.new(
          filter: %w[em i],
          replacement: lambda do |content, _node, options|
            next "" if content.strip.empty?

            "#{options[:em_delimiter]}#{content}#{options[:em_delimiter]}"
          end
        ),
        strong: Rule.new(
          filter: %w[strong b],
          replacement: lambda do |content, _node, options|
            next "" if content.strip.empty?

            "#{options[:strong_delimiter]}#{content}#{options[:strong_delimiter]}"
          end
        ),
        code: Rule.new(
          filter: lambda do |node, _options|
            has_siblings = node.previous_sibling || node.next_sibling
            is_code_block = node.parent_node&.node_name == "PRE" && !has_siblings
            node.node_name == "CODE" && !is_code_block
          end,
          replacement: lambda do |content, _node, _options|
            next "" if content.empty?

            content = content.gsub(/\r?\n|\r/, " ")
            extra_space =
              if content.match?(/\A`/) || content.match?(/\A .*?[^ ].* \z/) || content.match?(/`\z/)
                " "
              else
                ""
              end

            delimiter = "`"
            matches = content.scan(/`+/)
            delimiter += "`" while matches.include?(delimiter)

            "#{delimiter}#{extra_space}#{content}#{extra_space}#{delimiter}"
          end
        ),
        image: Rule.new(
          filter: "img",
          replacement: lambda do |_content, node, _options|
            alt = Utilities.escape_markdown(clean_attribute(node.get_attribute("alt")))
            src = escape_link_destination(node.get_attribute("src").to_s)
            title = clean_attribute(node.get_attribute("title"))
            title_part = title.empty? ? "" : %( "#{escape_link_title(title)}")
            src.empty? ? "" : "![#{alt}](#{src}#{title_part})"
          end
        )
      }
    end

    def clean_attribute(attribute)
      attribute.to_s.gsub(/(\n+\s*)+/, "\n")
    end

    def escape_link_destination(destination)
      escaped = destination.to_s.gsub(/([<>()])/, '\\\\\1')
      escaped.include?(" ") ? "<#{escaped}>" : escaped
    end

    def escape_link_title(title)
      title.to_s.gsub('"', '\"')
    end
  end
end
