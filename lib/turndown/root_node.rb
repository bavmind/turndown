module Turndown
  class RootNode
    ROOT_ID = "turndown-root".freeze

    class << self
      def build(input, options)
        root =
          if input.is_a?(String)
            document = Nokogiri::HTML5::Document.parse(%(<x-turndown id="#{ROOT_ID}">#{input}</x-turndown>))
            document.at_css("##{ROOT_ID}")
          else
            input.dup
          end

        normalize_pre(root)
        CollapseWhitespace.call(
          element: root,
          is_block: ->(node) { Utilities.is_block?(node) },
          is_void: ->(node) { Utilities.is_void?(node) },
          is_pre: options[:preformatted_code] ? ->(node) { pre_or_code?(node) } : nil
        )

        root
      end

      private

      def pre_or_code?(node)
        return false unless node.element?

        %w[pre code].include?(node.name.downcase)
      end

      def normalize_pre(root)
        root.css("pre br").each do |node|
          node.replace(Nokogiri::XML::Text.new("\n", node.document))
        end
      end
    end
  end
end
