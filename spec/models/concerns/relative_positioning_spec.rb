# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RelativePositioning do
  let_it_be(:default_user) { create_default(:user) }
  let_it_be(:project) { create(:project) }

  def create_issue(pos)
    create(:issue, project: project, relative_position: pos)
  end

  # Increase the range size to convice yourself that this covers ALL arrangements
  range = (101..104)
  indices = range.each_with_index.to_a.map(&:second)

  describe 'Mover' do
    let(:start) { ((range.first + range.last) / 2.0).floor }

    subject { RelativePositioning::Mover.new(start, range) }

    describe '#move_to_end' do
      shared_examples 'able to place a new item at the end' do
        it 'can place any new item' do
          new_item = create_issue(nil)

          subject.move_to_end(new_item)
          new_item.save!

          expect(new_item.relative_position).to eq(project.issues.maximum(:relative_position))
        end
      end

      shared_examples 'able to move existing items to the end' do
        it 'can move any existing item' do
          issue = issues[index]
          subject.move_to_end(issue)
          issue.save!
          project.reset

          expect(project.issues.pluck(:relative_position)).to all(be_between(range.first, range.last))
          expect(issue.relative_position).to eq(project.issues.maximum(:relative_position))
        end
      end

      context 'all positions are taken' do
        let_it_be(:issues) do
          range.map { |pos| create_issue(pos) }
        end

        it 'raises an error when placing a new item' do
          new_item = create(:issue, project: project, relative_position: nil)

          expect { subject.move_to_end(new_item) }.to raise_error(RelativePositioning::NoSpaceLeft)
        end

        where(:index) { indices }

        with_them do
          it_behaves_like 'able to move existing items to the end'
        end
      end

      context 'there are no siblings' do
        it_behaves_like 'able to place a new item at the end'
      end

      context 'there is only one sibling' do
        where(:pos) { range.to_a }

        with_them do
          let!(:issues) { [create_issue(pos)] }
          let(:index) { 0 }

          it_behaves_like 'able to place a new item at the end'

          it_behaves_like 'able to move existing items to the end'
        end
      end

      context 'at least one position is free' do
        where(:free_space, :index) do
          range.to_a.product((0..).take(range.size - 1).to_a)
        end

        with_them do
          let!(:issues) do
            range.reject { |x| x == free_space }.map { |pos| create_issue(pos) }
          end

          it_behaves_like 'able to place a new item at the end'

          it_behaves_like 'able to move existing items to the end'
        end
      end
    end

    describe '#move_to_start' do
      shared_examples 'able to place a new item at the start' do
        it 'can place any new item' do
          new_item = create_issue(nil)

          subject.move_to_start(new_item)
          new_item.save!

          expect(new_item.relative_position).to eq(project.issues.minimum(:relative_position))
        end
      end

      shared_examples 'able to move existing items to the start' do
        it 'can move any existing item' do
          issue = issues[index]
          subject.move_to_start(issue)
          issue.save!
          project.reset

          expect(project.issues.pluck(:relative_position)).to all(be_between(range.first, range.last))
          expect(issue.relative_position).to eq(project.issues.minimum(:relative_position))
        end
      end

      context 'all positions are taken' do
        let_it_be(:issues) do
          range.map { |pos| create_issue(pos) }
        end

        it 'raises an error when placing a new item' do
          new_item = create(:issue, project: project, relative_position: nil)

          expect { subject.move_to_start(new_item) }.to raise_error(RelativePositioning::NoSpaceLeft)
        end

        where(:index) { indices }

        with_them do
          it_behaves_like 'able to move existing items to the start'
        end
      end

      context 'there are no siblings' do
        it_behaves_like 'able to place a new item at the start'
      end

      context 'there is only one sibling' do
        where(:pos) { range.to_a }

        with_them do
          let!(:issues) { [create_issue(pos)] }
          let(:index) { 0 }

          it_behaves_like 'able to place a new item at the start'

          it_behaves_like 'able to move existing items to the start'
        end
      end

      context 'at least one position is free' do
        where(:free_space, :index) do
          range.to_a.product((0..).take(range.size - 1).to_a)
        end

        with_them do
          let!(:issues) do
            range.reject { |x| x == free_space }.map { |pos| create_issue(pos) }
          end

          it_behaves_like 'able to place a new item at the start'

          it_behaves_like 'able to move existing items to the start'
        end
      end
    end

    describe '#move' do
      shared_examples 'able to move a new item' do
        it 'can place any new item betwen two others' do
          new_item = create_issue(nil)

          subject.move(new_item, lhs, rhs)
          new_item.save!
          lhs.reset
          rhs.reset

          expect(new_item.relative_position).to be_between(range.first, range.last)
          expect(new_item.relative_position).to be_between(lhs.relative_position, rhs.relative_position)
        end

        it 'can place any new item after another' do
          new_item = create_issue(nil)

          subject.move(new_item, lhs, nil)
          new_item.save!
          lhs.reset

          expect(new_item.relative_position).to be_between(range.first, range.last)
          expect(new_item.relative_position).to be > lhs.relative_position
        end

        it 'can place any new item before another' do
          new_item = create_issue(nil)

          subject.move(new_item, nil, rhs)
          new_item.save!
          rhs.reset

          expect(new_item.relative_position).to be_between(range.first, range.last)
          expect(new_item.relative_position).to be < rhs.relative_position
        end
      end

      shared_examples 'able to move an existing item' do
        let(:item) { issues[index] }
        let(:positions) { project.reset.issues.pluck(:relative_position) }

        it 'can place any item betwen two others' do
          subject.move(item, lhs, rhs)
          item.save!
          lhs.reset
          rhs.reset

          expect(positions).to all(be_between(range.first, range.last))
          expect(positions).to match_array(positions.uniq)
          expect(item.relative_position).to be_between(lhs.relative_position, rhs.relative_position)
        end

        it 'can place any item after another' do
          subject.move(item, lhs, nil)
          item.save!
          lhs.reset

          expect(positions).to all(be_between(range.first, range.last))
          expect(positions).to match_array(positions.uniq)
          expect(item.relative_position).to be >= lhs.relative_position

          expected_sequence = [lhs, item].uniq
          sequence = project.issues
            .reorder(:relative_position)
            .where(relative_position: (expected_sequence.first.relative_position..expected_sequence.last.relative_position))

          expect(sequence).to eq(expected_sequence)
        end

        it 'can place any item before another' do
          subject.move(item, nil, rhs)
          item.save!
          rhs.reset

          expect(positions).to all(be_between(range.first, range.last))
          expect(positions).to match_array(positions.uniq)
          expect(item.relative_position).to be <= rhs.relative_position

          expected_sequence = [item, rhs].uniq
          sequence = project.issues
            .reorder(:relative_position)
            .where(relative_position: (expected_sequence.first.relative_position..expected_sequence.last.relative_position))

          expect(sequence).to eq(expected_sequence)
        end
      end

      context 'all positions are taken' do
        let_it_be(:issues) { range.map { |pos| create_issue(pos) } }

        where(:idx_a, :idx_b) do
          indices.product(indices).select { |a, b| a < b }
        end

        with_them do
          let(:lhs) { issues[idx_a] }
          let(:rhs) { issues[idx_b] }

          before do
            issues.each(&:reset)
          end

          it 'raises an error when placing a new item anywhere' do
            new_item = create_issue(nil)

            expect { subject.move(new_item, lhs, rhs) }
              .to raise_error(RelativePositioning::NoSpaceLeft)

            expect { subject.move(new_item, nil, rhs) }
              .to raise_error(RelativePositioning::NoSpaceLeft)

            expect { subject.move(new_item, lhs, nil) }
              .to raise_error(RelativePositioning::NoSpaceLeft)
          end

          where(:index) { indices }

          with_them do
            it_behaves_like 'able to move an existing item'
          end
        end
      end

      context 'there are no siblings' do
        it 'raises an ArgumentError when both first and last are nil' do
          new_item = create_issue(nil)

          expect { subject.move(new_item, nil, nil) }.to raise_error(ArgumentError)
        end
      end

      context 'there are a couple of siblings' do
        where(:pos_a, :pos_b) { range.to_a.product(range.to_a).reject { |x, y| x == y } }

        with_them do
          let!(:issues) { [range.first, pos_a, pos_b].sort.map { |p| create_issue(p) } }
          let(:index) { 0 }
          let(:lhs) { issues[1] }
          let(:rhs) { issues[2] }

          it_behaves_like 'able to move a new item'
          it_behaves_like 'able to move an existing item'
        end
      end

      context 'at least one position is free' do
        where(:free_space, :index, :pos_a, :pos_b) do
          is = indices.reverse.drop(1)

          range.to_a.product(is).product(is).product(is)
            .map(&:flatten)
            .select { |_, _, a, b| a < b }
        end

        with_them do
          let!(:issues) do
            range.reject { |x| x == free_space }.map { |pos| create_issue(pos) }
          end

          let(:lhs) { issues[pos_a] }
          let(:rhs) { issues[pos_b] }

          it_behaves_like 'able to move a new item'

          it_behaves_like 'able to move an existing item'
        end
      end
    end
  end
end
