# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RelativePositioning::ItemContext do
  let_it_be(:default_user) { create_default(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  def create_issue(pos)
    create(:issue, project: project, relative_position: pos)
  end

  # Increase the range size to convice yourself that this covers ALL arrangements
  range = (101..108)
  indices = (0..).take(range.size)

  let(:start) { ((range.first + range.last) / 2.0).floor }
  let(:subjects) { issues.map { |i| described_class.new(i.reset, range) } }

  context 'there are gaps at the start and end' do
    let_it_be(:issues) { (range.first.succ..range.last.pred).map { |pos| create_issue(pos) } }

    it 'is always possible to find a gap' do
      expect(subjects)
        .to all(have_attributes(find_next_gap_before: be_present, find_next_gap_after: be_present))
    end

    where(:index) { indices.reverse.drop(2) }

    with_them do
      subject { subjects[index] }

      it 'is possible to shift_right, which will consume the gap at the end' do
        subject.shift_right

        expect(subject.find_next_gap_after).not_to be_present
      end

      it 'is possible to shift_left, which will consume the gap at the start' do
        subject.shift_left

        expect(subject.find_next_gap_before).not_to be_present
      end
    end
  end

  context 'there is a gap of multiple spaces' do
    let_it_be(:issues) { [range.first, range.last].map { |pos| create_issue(pos) } }

    it 'is possible to find the gap from the right' do
      gap = Gitlab::RelativePositioning::Gap.new(range.last, range.first)

      expect(subjects.last).to have_attributes(
        find_next_gap_before: eq(gap),
        find_next_gap_after: be_nil
      )
    end

    it 'is possible to find the gap from the left' do
      gap = Gitlab::RelativePositioning::Gap.new(range.first, range.last)

      expect(subjects.first).to have_attributes(
        find_next_gap_before: be_nil,
        find_next_gap_after: eq(gap)
      )
    end
  end

  context 'there are several free spaces' do
    let_it_be(:issues) { range.select(&:even?).map { |pos| create_issue(pos) } }
    let_it_be(:gaps) do
      range.select(&:odd?).map do |pos|
        rhs = pos.succ.clamp(range.first, range.last)
        lhs = pos.pred.clamp(range.first, range.last)

        {
          before: Gitlab::RelativePositioning::Gap.new(rhs, lhs),
          after: Gitlab::RelativePositioning::Gap.new(lhs, rhs)
        }
      end
    end

    where(:current_pos) { range.select(&:even?) }

    with_them do
      let(:subject) { subjects.find { |s| s.relative_position == current_pos } }

      it 'finds the closest gap' do
        closest_gap_before = gaps
          .map { |gap| gap[:before] }
          .select { |gap| gap.start_pos <= subject.relative_position }
          .max_by { |gap| gap.start_pos }
        closest_gap_after = gaps
          .map { |gap| gap[:after] }
          .select { |gap| gap.start_pos >= subject.relative_position }
          .min_by { |gap| gap.start_pos }

        expect(subject).to have_attributes(
          find_next_gap_before: closest_gap_before,
          find_next_gap_after: closest_gap_after
        )
      end
    end
  end

  context 'there is at least one free space' do
    where(:free_space) { range.to_a }

    with_them do
      let(:issues) { range.reject { |x| x == free_space }.map { |p| create_issue(p) } }
      let(:gap_rhs) { free_space.succ.clamp(range.first, range.last) }
      let(:gap_lhs) { free_space.pred.clamp(range.first, range.last) }

      it 'can always find a gap before if there is space to the left' do
        expected_gap = Gitlab::RelativePositioning::Gap.new(gap_rhs, gap_lhs)

        to_the_right_of_gap = subjects.select { |s| free_space < s.relative_position }

        expect(to_the_right_of_gap)
          .to all(have_attributes(find_next_gap_before: eq(expected_gap)))
      end

      it 'can always find a gap after if there is space to the right' do
        expected_gap = Gitlab::RelativePositioning::Gap.new(gap_lhs, gap_rhs)

        to_the_left_of_gap = subjects.select { |s| s.relative_position < free_space }

        expect(to_the_left_of_gap)
          .to all(have_attributes(find_next_gap_after: eq(expected_gap)))
      end
    end
  end
end
