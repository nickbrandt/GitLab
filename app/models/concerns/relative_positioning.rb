# frozen_string_literal: true

# This module makes it possible to handle items as a list, where the order of items can be easily altered
# Requirements:
#
# The model must have the following named columns:
#  - id: integer
#  - relative_position: integer
#
# The model must support a concept of siblings via a child->parent relationship,
# to enable rebalancing and `GROUP BY` in queries.
# - example: project -> issues, project is the parent relation (issues table has a parent_id column)
#
# Two class methods must be defined when including this concern:
#
#     include RelativePositioning
#
#     # base query used for the position calculation
#     def self.relative_positioning_query_base(issue)
#       where(deleted: false)
#     end
#
#     # column that should be used in GROUP BY
#     def self.relative_positioning_parent_column
#       :project_id
#     end
#
module RelativePositioning
  class Gap
    attr_reader :start_pos, :end_pos

    def initialize(start_pos, end_pos)
      @start_pos, @end_pos = start_pos, end_pos
    end

    def delta
      ((start_pos - end_pos) / 2.0).abs.ceil.clamp(0, RelativePositioning::IDEAL_DISTANCE)
    end
  end

  class ItemContext
    include Gitlab::Utils::StrongMemoize

    attr_reader :object, :model_class, :range
    attr_accessor :ignoring

    def initialize(object, range)
      @object = object
      @range = range
      @model_class = object.class
    end

    def min_relative_position
      strong_memoize(:min_relative_position) { calculate_relative_position('MIN') }
    end

    def max_relative_position
      strong_memoize(:max_relative_position) { calculate_relative_position('MAX') }
    end

    def prev_relative_position
      calculate_relative_position('MAX') { |r| nextify(r, false) } if object.relative_position
    end

    def next_relative_position
      calculate_relative_position('MIN') { |r| nextify(r) } if object.relative_position
    end

    def nextify(relation, gt = true)
      op = gt ? '>' : '<'
      relation.where("relative_position #{op} ?", object.relative_position)
    end

    def relative_siblings(relation = scoped_items)
      relation.id_not_in(object.id)
    end

    # Handles the possibility that the position is already occupied by a sibling
    def place_at_position(position, lhs)
      current_occupant = relative_siblings.find_by(relative_position: position)

      if current_occupant.present?
        Mover.new(position, range).move(object, lhs.object, current_occupant)
      else
        object.relative_position = position
      end
    end

    def lhs_neighbour
      scoped_items
        .where('relative_position < ?', relative_position)
        .reorder(relative_position: :desc)
        .first
        .then { |x| neighbour(x) }
    end

    def rhs_neighbour
      scoped_items
        .where('relative_position > ?', relative_position)
        .reorder(relative_position: :asc)
        .first
        .then { |x| neighbour(x) }
    end

    def neighbour(item)
      return unless item.present?

      n = self.class.new(item, range)
      n.ignoring = ignoring
      n
    end

    def scoped_items
      r = model_class.relative_positioning_query_base(object)
      r = r.id_not_in(ignoring.id) if ignoring.present?
      r
    end

    def calculate_relative_position(calculation)
      # When calculating across projects, this is much more efficient than
      # MAX(relative_position) without the GROUP BY, due to index usage:
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/54276#note_119340977
      relation = scoped_items
                   .order(Gitlab::Database.nulls_last_order('position', 'DESC'))
                   .group(grouping_column)
                   .limit(1)

      relation = yield relation if block_given?

      relation
        .pluck(grouping_column, Arel.sql("#{calculation}(relative_position) AS position"))
        .first&.last
    end

    def grouping_column
      model_class.relative_positioning_parent_column
    end

    def max_sibling
      sib = relative_siblings
        .order(Gitlab::Database.nulls_last_order('relative_position', 'DESC'))
        .first

      self.class.new(sib, range)
    end

    def min_sibling
      sib = relative_siblings
        .order(Gitlab::Database.nulls_last_order('relative_position', 'ASC'))
        .first

      self.class.new(sib, range)
    end

    def shift_left
      move_sequence_before(true)
      object.reset
    end

    def shift_right
      move_sequence_after(true)
      object.reset
    end

    def create_space_left(gap: nil)
      move_sequence_before(false, next_gap: gap)
    end

    def create_space_right(gap: nil)
      move_sequence_after(false, next_gap: gap)
    end

    # Moves the sequence before the current item to the middle of the next gap
    # For example, we have
    #
    #   5 . . . . . 11 12 13 14 [15] 16 . 17
    #               -----------
    #
    # This moves the sequence [11 12 13 14] to [8 9 10 11], so we have:
    #
    #   5 . . 8 9 10 11 . . . [15] 16 . 17
    #         ---------
    #
    # Creating a gap to the left of the current item. We can understand this as
    # dividing the 5 spaces between 5 and 11 into two smaller gaps of 2 and 3.
    #
    # If `include_self` is true, the current item will also be moved, creating a
    # gap to the right of the current item:
    #
    #   5 . . 8 9 10 11 [14] . . . 16 . 17
    #         --------------
    #
    # As an optimization, the gap can be precalculated and passed to this method.
    #
    # @api private
    # @raises NoSpaceLeft if the sequence cannot be moved
    def move_sequence_before(include_self = false, next_gap: find_next_gap_before)
      raise NoSpaceLeft unless next_gap.present?

      delta = next_gap.delta

      move_sequence(next_gap.start_pos, relative_position, -delta, include_self)
    end

    # Moves the sequence after the current item to the middle of the next gap
    # For example, we have:
    #
    #   8 . 10 [11] 12 13 14 15 . . . . . 21
    #               -----------
    #
    # This moves the sequence [12 13 14 15] to [15 16 17 18], so we have:
    #
    #   8 . 10 [11] . . . 15 16 17 18 . . 21
    #                     -----------
    #
    # Creating a gap to the right of the current item. We can understand this as
    # dividing the 5 spaces between 15 and 21 into two smaller gaps of 3 and 2.
    #
    # If `include_self` is true, the current item will also be moved, creating a
    # gap to the left of the current item:
    #
    #   8 . 10 . . . [14] 15 16 17 18 . . 21
    #                ----------------
    #
    # As an optimization, the gap can be precalculated and passed to this method.
    #
    # @api private
    # @raises NoSpaceLeft if the sequence cannot be moved
    def move_sequence_after(include_self = false, next_gap: find_next_gap_after)
      raise NoSpaceLeft unless next_gap.present?

      delta = next_gap.delta

      move_sequence(relative_position, next_gap.start_pos, delta, include_self)
    end

    def move_sequence(start_pos, end_pos, delta, include_self = false)
      relation = include_self ? scoped_items : relative_siblings

      relation
        .where('relative_position BETWEEN ? AND ?', start_pos, end_pos)
        .update_all("relative_position = relative_position + #{delta}")
    end

    def find_next_gap_before
      items_with_next_pos = scoped_items
                              .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position DESC) AS next_pos')
                              .where('relative_position <= ?', relative_position)
                              .order(relative_position: :desc)

      find_next_gap(items_with_next_pos, range.first)
    end

    def find_next_gap_after
      items_with_next_pos = scoped_items
                              .select('relative_position AS pos, LEAD(relative_position) OVER (ORDER BY relative_position ASC) AS next_pos')
                              .where('relative_position >= ?', relative_position)
                              .order(:relative_position)

      find_next_gap(items_with_next_pos, range.last)
    end

    def find_next_gap(items_with_next_pos, default_end)
      gap = model_class
        .from(items_with_next_pos, :items)
        .where('next_pos IS NULL OR ABS(pos::bigint - next_pos::bigint) >= ?', RelativePositioning::MIN_GAP)
        .limit(1)
        .pluck(:pos, :next_pos)
        .first

      return if gap.nil? || gap.first == default_end

      Gap.new(gap.first, gap.second || default_end)
    end

    def relative_position
      object.relative_position
    end
  end

  class Mover
    attr_reader :range, :start_position

    def initialize(start, range)
      @range = range
      @start_position = start
    end

    def move_to_end(object)
      focus = context(object, ignoring: object)
      max_pos = focus.max_relative_position

      move_to_range_end(focus, max_pos)
    end

    def move_to_start(object)
      focus = context(object, ignoring: object)
      min_pos = focus.min_relative_position

      move_to_range_start(focus, min_pos)
    end

    def move(object, first, last)
      raise ArgumentError unless object && (first || last) && (first != last)
      # Moving a object next to itself is a no-op
      return if object == first || object == last

      lhs = context(first, ignoring: object)
      rhs = context(last, ignoring: object)
      focus = context(object)

      lhs ||= rhs.lhs_neighbour
      rhs ||= lhs.rhs_neighbour

      if lhs.nil?
        move_to_range_start(focus, rhs.relative_position)
      elsif rhs.nil?
        move_to_range_end(focus, lhs.relative_position)
      else
        pos_left, pos_right = create_space_between(lhs, rhs)
        desired_position = position_between(pos_left, pos_right)
        focus.place_at_position(desired_position, lhs)
      end
    end

    def context(object, ignoring: nil)
      return unless object

      c = ItemContext.new(object, range)
      c.ignoring = ignoring
      c
    end

    private

    def gap_too_small?(pos_a, pos_b)
      return false unless pos_a && pos_b

      (pos_a - pos_b).abs < MIN_GAP
    end

    def move_to_range_end(context, max_pos)
      range_end = range.last + 1

      new_pos = if max_pos.nil?
                  start_position
                elsif gap_too_small?(max_pos, range_end)
                  max = context.max_sibling
                  max.ignoring = context.object
                  max.shift_left
                  position_between(max.relative_position, range_end)
                else
                  position_between(max_pos, range_end)
                end

      context.object.relative_position = new_pos
    end

    def move_to_range_start(context, min_pos)
      range_end = range.first - 1

      new_pos = if min_pos.nil?
                  start_position
                elsif gap_too_small?(min_pos, range_end)
                  sib = context.min_sibling
                  sib.ignoring = context.object
                  sib.shift_right
                  position_between(sib.relative_position, range_end)
                else
                  position_between(min_pos, range_end)
                end

      context.object.relative_position = new_pos
    end

    def create_space_between(lhs, rhs)
      pos_left = lhs&.relative_position
      pos_right = rhs&.relative_position

      return [pos_left, pos_right] unless gap_too_small?(pos_left, pos_right)

      gap = rhs.find_next_gap_before

      if gap.present?
        rhs.create_space_left(gap: gap)
        [pos_left - gap.delta, pos_right]
      else
        gap = lhs.find_next_gap_after
        lhs.create_space_right(gap: gap)
        [pos_left, pos_right + gap.delta]
      end
    end

    # This method takes two integer values (positions) and
    # calculates the position between them. The range is huge as
    # the maximum integer value is 2147483647.
    #
    # We avoid open ranges by clamping the range to [MIN_POSITION, MAX_POSITION].
    #
    # Then we handle one of three cases:
    #  - If the gap is too small, we raise NoSpaceLeft
    #  - If the gap is larger than MAX_GAP, we place the new position at most
    #    IDEAL_DISTANCE from the edge of the gap.
    #  - otherwise we place the new position at the midpoint.
    #
    # The new position will always satisfy: pos_before <= midpoint <= pos_after
    #
    # As a precondition, the gap between pos_before and pos_after MUST be >= 2.
    # If the gap is too small, NoSpaceLeft is raised.
    #
    # @raises NoSpaceLeft
    def position_between(pos_before, pos_after)
      pos_before ||= range.first
      pos_after ||= range.last

      pos_before, pos_after = [pos_before, pos_after].sort

      gap_width = pos_after - pos_before

      if gap_too_small?(pos_before, pos_after)
        raise RelativePositioning::NoSpaceLeft
      elsif gap_width > RelativePositioning::MAX_GAP
        if pos_before <= range.first
          pos_after - RelativePositioning::IDEAL_DISTANCE
        elsif pos_after >= range.last
          pos_before + RelativePositioning::IDEAL_DISTANCE
        else
          midpoint(pos_before, pos_after)
        end
      else
        midpoint(pos_before, pos_after)
      end
    end

    def midpoint(lower_bound, upper_bound)
      ((lower_bound + upper_bound) / 2.0).ceil.clamp(lower_bound, upper_bound - 1)
    end
  end

  extend ActiveSupport::Concern

  STEPS = 10
  IDEAL_DISTANCE = 2**(STEPS - 1) + 1

  MIN_POSITION = Gitlab::Database::MIN_INT_VALUE
  START_POSITION = 0
  MAX_POSITION = Gitlab::Database::MAX_INT_VALUE

  MAX_GAP = IDEAL_DISTANCE * 2
  MIN_GAP = 2

  NoSpaceLeft = Class.new(StandardError)

  class_methods do
    def move_nulls_to_end(objects)
      move_nulls(objects, at_end: true)
    end

    def move_nulls_to_start(objects)
      move_nulls(objects, at_end: false)
    end

    private

    # @api private
    def gap_size(context, gaps:, at_end:, starting_from:)
      total_width = IDEAL_DISTANCE * gaps
      size = if at_end && starting_from + total_width >= MAX_POSITION
               (MAX_POSITION - starting_from) / gaps
             elsif !at_end && starting_from - total_width <= MIN_POSITION
               (starting_from - MIN_POSITION) / gaps
             else
               IDEAL_DISTANCE
             end

      return [size, starting_from] if size >= MIN_GAP

      if at_end
        terminus = context.max_sibling
        terminus.shift_left
        max_relative_position = terminus.relative_position
        [[(MAX_POSITION - max_relative_position) / gaps, IDEAL_DISTANCE].min, max_relative_position]
      else
        terminus = min_sibling
        terminus.shift_right
        min_relative_position = terminus.relative_position
        [[(min_relative_position - MIN_POSITION) / gaps, IDEAL_DISTANCE].min, min_relative_position]
      end
    end

    # @api private
    # @param [Array<RelativePositioning>] objects The objects to give positions to. The relative
    #                                             order will be preserved (i.e. when this method returns,
    #                                             objects.first.relative_position < objects.last.relative_position)
    # @param [Boolean] at_end: The placement.
    #                          If `true`, then all objects with `null` positions are placed _after_
    #                          all siblings with positions. If `false`, all objects with `null`
    #                          positions are placed _before_ all siblings with positions.
    # @returns [Number] The number of moved records.
    def move_nulls(objects, at_end:)
      objects = objects.reject(&:relative_position)
      return 0 if objects.empty?

      number_of_gaps = objects.size # 1 to the nearest neighbour, and one between each
      mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))
      representative = mover.context(objects.first)

      position = if at_end
                   representative.max_relative_position
                 else
                   representative.min_relative_position
                 end

      position ||= START_POSITION # If there are no positioned siblings, start from START_POSITION

      gap = 0
      attempts = 10 # consolidate up to 10 gaps to find enough space
      while gap < 1 && attempts > 0
        gap, position = gap_size(representative, gaps: number_of_gaps, at_end: at_end, starting_from: position)
        attempts -= 1
      end

      # Allow placing items next to each other, if we have to.
      gap = 1 if gap < MIN_GAP
      delta = at_end ? gap : -gap
      indexed = (at_end ? objects : objects.reverse).each_with_index

      # Some classes are polymorphic, and not all siblings are in the same table.
      by_model = indexed.group_by { |pair| pair.first.class }
      lower_bound, upper_bound = at_end ? [position, MAX_POSITION] : [MIN_POSITION, position]

      by_model.each do |model, pairs|
        model.transaction do
          pairs.each_slice(100) do |batch|
            # These are known to be integers, one from the DB, and the other
            # calculated by us, and thus safe to interpolate
            values = batch.map do |obj, i|
              desired_pos = position + delta * (i + 1)
              pos = desired_pos.clamp(lower_bound, upper_bound)
              obj.relative_position = pos
              "(#{obj.id}, #{pos})"
            end.join(', ')

            model.connection.exec_query(<<~SQL, "UPDATE #{model.table_name} positions")
              WITH cte(cte_id, new_pos) AS (
               SELECT *
               FROM (VALUES #{values}) as t (id, pos)
              )
              UPDATE #{model.table_name}
              SET relative_position = cte.new_pos
              FROM cte
              WHERE cte_id = id
            SQL
          end
        end
      end

      objects.size
    end
  end

  def move_between(before, after)
    mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))
    before, after = [before, after].sort_by(&:relative_position) if before && after

    mover.move(self, before, after)
  end

  def move_after(before = self)
    mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))

    mover.move(self, before, nil)
  end

  def move_before(after = self)
    mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))

    mover.move(self, nil, after)
  end

  def move_to_end
    mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))

    mover.move_to_end(self)
  rescue NoSpaceLeft
    self.relative_position = MAX_POSITION
  end

  def move_to_start
    mover = Mover.new(START_POSITION, (MIN_POSITION..MAX_POSITION))

    mover.move_to_start(self)
  rescue NoSpaceLeft
    self.relative_position = MIN_POSITION
  end
end
