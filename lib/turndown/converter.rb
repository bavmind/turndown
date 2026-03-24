module Turndown
  class Converter
    attr_reader :options, :rules

    def initialize(options = {})
      normalized_options = normalize_options(options)
      @options = Utilities.extend(default_options, normalized_options)
      @rules = Rules.new(@options)
    end

    def convert(input)
      raise TypeError, "#{input} is not a string, or an element/document/fragment node." unless can_convert?(input)
      return "" if input == ""

      output = process(RootNode.build(input, options))
      post_process(output)
    end

    def use(plugin)
      if plugin.is_a?(Array)
        plugin.each { |entry| use(entry) }
      elsif plugin.respond_to?(:call)
        plugin.call(self)
      else
        raise TypeError, "plugin must be a callable or an Array of callables"
      end

      self
    end

    def add_rule(name, filter:, replacement:, append: nil)
      rules.add(name, Rule.new(filter: filter, replacement: replacement, append: append))
      self
    end

    def keep(filter)
      rules.keep(filter)
      self
    end

    def remove(filter)
      rules.remove(filter)
      self
    end

    def escape(string)
      Utilities.escape_markdown(string)
    end

    private

    def process(parent_raw)
      parent = parent_raw.is_a?(Node) ? parent_raw : Node.new(parent_raw, options)

      parent.child_nodes.reduce("") do |output, node|
        replacement =
          if node.text_node?
            node.code? ? node.node_value : escape(node.node_value)
          elsif node.element?
            replacement_for_node(node)
          else
            ""
          end

        join(output, replacement)
      end
    end

    def post_process(output)
      rules.each do |rule|
        appended = rule.append(options)
        output = join(output, appended) unless appended.empty?
      end

      output.sub(/\A[\t\r\n]+/, "").sub(/\s+\z/, "")
    end

    def replacement_for_node(node)
      rule = rules.for_node(node)
      content = process(node)
      whitespace = node.flanking_whitespace
      if !whitespace[:leading].empty? || !whitespace[:trailing].empty?
        content = content.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
      end
      "#{whitespace[:leading]}#{rule.replacement(content, node, options)}#{whitespace[:trailing]}"
    end

    def join(output, replacement)
      s1 = Utilities.trim_trailing_newlines(output)
      s2 = Utilities.trim_leading_newlines(replacement)
      newlines = [output.length - s1.length, replacement.length - s2.length].max
      separator = "\n\n"[0, newlines]
      "#{s1}#{separator}#{s2}"
    end

    def normalize_options(options)
      options.each_with_object({}) do |(key, value), normalized|
        normalized[normalize_option_key(key)] = value
      end
    end

    def normalize_option_key(key)
      key.to_s.gsub(/([A-Z])/, '_\1').downcase.sub(/\A_/, "").to_sym
    end

    def can_convert?(input)
      input.is_a?(String) || input.is_a?(Nokogiri::XML::Node) || input.is_a?(Nokogiri::XML::DocumentFragment)
    end

    def default_options
      {
        rules: CommonMarkRules.build,
        heading_style: "setext",
        hr: "* * *",
        bullet_list_marker: "*",
        code_block_style: "indented",
        fence: "```",
        em_delimiter: "_",
        strong_delimiter: "**",
        link_style: "inlined",
        link_reference_style: "full",
        br: "  ",
        preformatted_code: false,
        blank_replacement: ->(_content, node, _options) { node.block? ? "\n\n" : "" },
        keep_replacement: lambda do |_content, node, _options|
          node.block? ? "\n\n#{node.outer_html}\n\n" : node.outer_html
        end,
        default_replacement: lambda do |content, node, _options|
          node.block? ? "\n\n#{content}\n\n" : content
        end
      }
    end
  end
end
