# frozen_string_literal: true

module Turndown
  module Plugins
    # Resolves table cells onto a logical grid, so merged cells and headerless
    # tables survive conversion. This is NOT part of upstream Turndown or
    # turndown-plugin-gfm.
    #
    #   converter.use(Turndown::Plugins::TableGrid)
    #
    # Rendering builds on the GFM table rules, which this plugin registers for
    # you. To use the rest of GFM as well, load it first so these rules take
    # precedence:
    #
    #   converter.use([Turndown::Plugins::GFM, Turndown::Plugins::TableGrid])
    #
    # Markdown has no merged cells, so `table_spans` picks how they are
    # represented:
    #
    #   :blank         content sits in its true column and covered positions are
    #                  left empty. Valid GFM, loses the merge.
    #   :flatten       the cell repeats into every position it covers, so a row
    #                  lifted out of the table still makes sense on its own.
    #   :multimarkdown row spans emit `^^` and column spans emit trailing pipes,
    #                  per MultiMarkdown. Lossless, but a row referring to the
    #                  one above it cannot be read in isolation.
    #
    # Loading the plugin always resolves the grid and pads every row to the
    # table's full width. Without that, a spanned cell shifts its neighbours
    # into the wrong columns.
    module TableGrid
      ROWSPAN_MARKER = "^^"
      CELL_NAMES = %w[th td].freeze
      SPAN_STRATEGIES = %i[blank flatten multimarkdown].freeze
      HEADERLESS_MODES = %i[keep blank_header first_row_header].freeze

      module_function

      def call(converter)
        GFM::Tables.call(converter)

        converter.add_transform(->(root, options) { resolve_tables(root, options) })

        converter.add_rule(
          :table_grid_cell,
          filter: CELL_NAMES,
          replacement: ->(content, node, _options) { span_aware_cell(content, node) }
        )

        # The delimiter row defines the table's column count, so a spanned
        # heading cell needs one delimiter per column it covers. GFM emits one
        # per cell.
        converter.add_rule(
          :table_grid_row,
          filter: "tr",
          replacement: lambda do |content, node, _options|
            next "" if GFM::Tables.empty_row?(node)

            delimiters = GFM::Tables.heading_row?(node) ? delimiter_row(node) : ""
            "\n#{content}#{delimiters.empty? ? '' : "\n#{delimiters}"}"
          end
        )

        converter
      end

      # Mirrors GFM::Tables.cell, except a column span widens the cell with
      # extra trailing pipes rather than emitting a second cell.
      def span_aware_cell(content, node)
        index = node.parent_node.children.find_index { |child| child.same_node?(node) } || 0
        prefix = index.zero? ? "| " : " "
        colspan = [node.get_attribute("colspan").to_i, 1].max
        "#{prefix}#{content} #{'|' * colspan}"
      end

      def delimiter_row(node)
        markers = []

        node.child_nodes.each do |child|
          next unless CELL_NAMES.include?(child.node_name.downcase)

          marker = GFM::ALIGN_MAP.fetch(child.get_attribute("align").to_s.downcase, "---")
          [child.get_attribute("colspan").to_i, 1].max.times { markers << marker }
        end

        markers.each_with_index.map { |marker, index| "#{index.zero? ? '| ' : ' '}#{marker} |" }.join
      end

      def resolve_tables(root, options)
        spans = span_strategy(options)
        headerless = headerless_mode(options)

        root.css("table").each do |table|
          # Row spans resolve per row group, but width belongs to the whole
          # table — a short <tbody> row still pads out to the <thead> width.
          grids = row_groups(table).map { |rows| build_grid(rows) }
          width = grids.map { |grid| grid[:width] }.max.to_i

          grids.each do |grid|
            grid[:rows].each_with_index do |row, row_index|
              rebuild_row(row, row_index, grid[:placements], width, spans)
            end
          end

          apply_headerless(table, headerless, options, width)
        end
      end

      def span_strategy(options)
        value = options.fetch(:table_spans, :blank).to_sym
        return value if SPAN_STRATEGIES.include?(value)

        raise ArgumentError, "table_spans must be one of #{SPAN_STRATEGIES.inspect}, got #{value.inspect}"
      end

      def headerless_mode(options)
        value = options.fetch(:headerless_tables, :keep).to_sym
        return value if HEADERLESS_MODES.include?(value)

        raise ArgumentError, "headerless_tables must be one of #{HEADERLESS_MODES.inspect}, got #{value.inspect}"
      end

      # Row spans are not carried across thead/tbody/tfoot, so each group is
      # resolved on its own grid.
      def row_groups(table)
        groups = []
        loose = []

        table.element_children.each do |child|
          case child.name.downcase
          when "tr"
            loose << child
          when "thead", "tbody", "tfoot"
            groups << loose unless loose.empty?
            loose = []
            rows = child.element_children.select { |node| node.name.casecmp("tr").zero? }
            groups << rows unless rows.empty?
          end
        end

        groups << loose unless loose.empty?
        groups
      end

      # Places every cell in a row group onto a grid, so a cell's column is
      # where it actually lands rather than its index among its siblings.
      def build_grid(rows)
        return { rows: rows, placements: {}, width: 0 } if rows.empty?

        occupied = {}
        placements = {}

        rows.each_with_index do |row, row_index|
          column = 0

          cells_of(row).each do |node|
            column += 1 while occupied[[row_index, column]]

            colspan = colspan_of(node)
            rowspan = [rowspan_of(node, rows.length - row_index), rows.length - row_index].min
            placement = { cell: node, origin: row_index, colspan: colspan }

            (row_index...(row_index + rowspan)).each do |covered_row|
              placements[[covered_row, column]] = placement
              (column...(column + colspan)).each { |covered| occupied[[covered_row, covered]] = true }
            end

            column += colspan
          end
        end

        width = occupied.keys.map { |(_row, column)| column + 1 }.max.to_i
        { rows: rows, placements: placements, width: width }
      end

      def rebuild_row(row, row_index, placements, width, spans)
        ordered = []
        column = 0

        while column < width
          placement = placements[[row_index, column]]

          if placement.nil?
            ordered << empty_cell(row, "td")
            column += 1
            next
          end

          ordered << if placement[:origin] == row_index
                       origin_cell(placement, spans)
                     else
                       continuation_cell(row, placement, spans)
                     end

          # :multimarkdown folds the extra columns into trailing pipes on the
          # cell itself; every other strategy needs a real cell per column.
          unless spans == :multimarkdown
            covered = ordered.last
            (placement[:colspan] - 1).times do
              ordered << (spans == :flatten ? covered.dup : empty_cell(row, placement[:cell].name))
            end
          end

          column += placement[:colspan]
        end

        row.children.each(&:unlink)
        ordered.each { |node| row.add_child(node) }
      end

      def origin_cell(placement, spans)
        node = placement[:cell]
        node.remove_attribute("rowspan")

        if spans == :multimarkdown && placement[:colspan] > 1
          node["colspan"] = placement[:colspan].to_s
        else
          node.remove_attribute("colspan")
        end

        node
      end

      def continuation_cell(row, placement, spans)
        # :flatten repeats the cell so every row stands on its own — the point
        # being that a row can be lifted out of the table and still make sense.
        return placement[:cell].dup if spans == :flatten

        node = empty_cell(row, placement[:cell].name)
        return node unless spans == :multimarkdown

        node.content = ROWSPAN_MARKER
        node["colspan"] = placement[:colspan].to_s if placement[:colspan] > 1
        node
      end

      def empty_cell(row, name)
        row.document.create_element(CELL_NAMES.include?(name.downcase) ? name.downcase : "td")
      end

      def cells_of(row)
        row.element_children.select { |node| CELL_NAMES.include?(node.name.downcase) }
      end

      def colspan_of(node)
        value = node["colspan"].to_s.strip.to_i
        value < 1 ? 1 : value
      end

      # rowspan="0" means "to the end of the row group" per the HTML spec.
      def rowspan_of(node, remaining)
        raw = node["rowspan"].to_s.strip
        return [remaining, 1].max if raw == "0"

        value = raw.to_i
        value < 1 ? 1 : value
      end

      def apply_headerless(table, mode, options, width)
        return if mode == :keep
        return if width.zero?

        # Reuse GFM's own heading detection so the two plugins never disagree
        # about what counts as a header row.
        return if Node.new(table, options).rows.any? { |row| GFM::Tables.heading_row?(row) }

        row = first_row(table)
        return unless row

        case mode
        when :first_row_header then promote_row_to_header(row)
        when :blank_header then insert_empty_header(row, width)
        end
      end

      def first_row(table)
        row_groups(table).flatten.first
      end

      def promote_row_to_header(row)
        cells_of(row).each { |node| node.name = "th" }
      end

      def insert_empty_header(row, width)
        header = row.document.create_element("tr")
        width.times { header.add_child(row.document.create_element("th")) }
        row.add_previous_sibling(header)
      end

      private_class_method :span_aware_cell, :delimiter_row, :resolve_tables, :span_strategy,
                           :headerless_mode, :row_groups, :build_grid, :rebuild_row, :origin_cell,
                           :continuation_cell, :empty_cell, :cells_of, :colspan_of, :rowspan_of,
                           :apply_headerless, :first_row, :promote_row_to_header, :insert_empty_header
    end
  end
end
