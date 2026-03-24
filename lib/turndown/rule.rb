module Turndown
  class Rule
    attr_reader :filter

    def initialize(filter: nil, replacement:, append: nil)
      @filter = filter
      @replacement = replacement
      @append = append
    end

    def matches?(node, options)
      case filter
      when String, Symbol
        filter.to_s == node.node_name_downcase
      when Array
        filter.map(&:to_s).include?(node.node_name_downcase)
      when Proc
        filter.call(node, options)
      when nil
        false
      else
        raise TypeError, "`filter` needs to be a string, array, or function"
      end
    end

    def replacement(content, node, options)
      @replacement.call(content, node, options)
    end

    def append(options)
      return "" unless @append

      @append.call(options)
    end
  end
end
