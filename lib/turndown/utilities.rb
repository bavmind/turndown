module Turndown
  module Utilities
    BLOCK_ELEMENTS = %w[
      ADDRESS ARTICLE ASIDE AUDIO BLOCKQUOTE BODY CANVAS CENTER DD DIR DIV DL DT
      FIELDSET FIGCAPTION FIGURE FOOTER FORM FRAMESET H1 H2 H3 H4 H5 H6 HEADER
      HGROUP HR HTML ISINDEX LI MAIN MENU NAV NOFRAMES NOSCRIPT OL OUTPUT P PRE
      SECTION TABLE TBODY TD TFOOT TH THEAD TR UL
    ].freeze

    VOID_ELEMENTS = %w[
      AREA BASE BR COL COMMAND EMBED HR IMG INPUT KEYGEN LINK META PARAM SOURCE
      TRACK WBR
    ].freeze

    MEANINGFUL_WHEN_BLANK_ELEMENTS = %w[
      A TABLE THEAD TBODY TFOOT TH TD IFRAME SCRIPT AUDIO VIDEO
    ].freeze

    module_function

    def extend(destination, *sources)
      sources.each do |source|
        source.each do |key, value|
          destination[key] = value
        end
      end
      destination
    end

    def repeat(character, count)
      character * count
    end

    def trim_leading_newlines(string)
      string.sub(/\A\n+/, "")
    end

    def trim_trailing_newlines(string)
      index_end = string.length
      index_end -= 1 while index_end.positive? && string[index_end - 1] == "\n"
      string[0, index_end]
    end

    def trim_newlines(string)
      trim_trailing_newlines(trim_leading_newlines(string))
    end

    def is_block?(node)
      node_name_in?(node, BLOCK_ELEMENTS)
    end

    def is_void?(node)
      node_name_in?(node, VOID_ELEMENTS)
    end

    def has_void?(node)
      has_descendant_named?(node, VOID_ELEMENTS)
    end

    def is_meaningful_when_blank?(node)
      node_name_in?(node, MEANINGFUL_WHEN_BLANK_ELEMENTS)
    end

    def has_meaningful_when_blank?(node)
      has_descendant_named?(node, MEANINGFUL_WHEN_BLANK_ELEMENTS)
    end

    def escape_markdown(string)
      string
        .gsub(/\\/) { '\\' * 2 }
        .gsub(/\*/) { '\*' }
        .gsub(/\A-/) { '\-' }
        .gsub(/\A\+ /) { '\+ ' }
        .gsub(/\A(=+)/) { "\\#{$1}" }
        .gsub(/\A(\#{1,6}) /) { "\\#{$1} " }
        .gsub(/`/) { '\`' }
        .gsub(/\A~~~/) { '\~~~' }
        .gsub(/\[/) { '\[' }
        .gsub(/\]/) { '\]' }
        .gsub(/\A>/) { '\>' }
        .gsub(/_/) { '\_' }
        .gsub(/\A(\d+)\. /) { "#{$1}\\. " }
    end

    def camel_to_snake(string)
      string.gsub(/([A-Z])/, '_\1').downcase.sub(/\A_/, "")
    end

    def node_name_in?(node, names)
      node.respond_to?(:node_name) && names.include?(node.node_name)
    end

    def has_descendant_named?(node, names)
      return false unless node.respond_to?(:css)

      selector = names.map(&:downcase).join(",")
      node.css(selector).any?
    end
  end
end
