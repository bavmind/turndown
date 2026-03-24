module Turndown
  class Rules
    def initialize(options)
      @options = options
      @keep = []
      @remove = []
      @blank_rule = Rule.new(replacement: options[:blank_replacement])
      @keep_replacement = options[:keep_replacement]
      @default_rule = Rule.new(replacement: options[:default_replacement])
      @array = options.fetch(:rules).values.dup
    end

    def add(_key, rule)
      @array.unshift(rule)
    end

    def keep(filter)
      @keep.unshift(
        Rule.new(
          filter: filter,
          replacement: @keep_replacement
        )
      )
    end

    def remove(filter)
      @remove.unshift(
        Rule.new(
          filter: filter,
          replacement: ->(_content, _node, _options) { "" }
        )
      )
    end

    def for_node(node)
      return @blank_rule if node.blank?

      find_rule(@array, node) || find_rule(@keep, node) || find_rule(@remove, node) || @default_rule
    end

    def each(&block)
      @array.each(&block)
    end

    private

    def find_rule(rules, node)
      rules.find { |rule| rule.matches?(node, @options) }
    end
  end
end
