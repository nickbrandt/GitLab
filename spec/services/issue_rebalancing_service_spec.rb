# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:start) { RelativePositioning::START_POSITION }
  let_it_be(:max_pos) { RelativePositioning::MAX_POSITION }
  let_it_be(:min_pos) { RelativePositioning::MIN_POSITION }
  let_it_be(:clump_size) { 300 }

  let_it_be(:unclumped) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: start + (1024 * i))
    end
  end

  let_it_be(:end_clump) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: max_pos - i)
    end
  end

  let_it_be(:start_clump) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: min_pos + i)
    end
  end

  def issues_in_position_order
    project.reload.issues.reorder(relative_position: :asc).to_a
  end

  it 'rebalances a set of issues with clumps at the end and start' do
    all_issues = start_clump + unclumped + end_clump.reverse

    service = described_class.new(project.issues.first)

    expect { service.execute }.not_to change { issues_in_position_order.map(&:id) }

    all_issues.each(&:reset)

    gaps = all_issues.take(all_issues.count - 1).zip(all_issues.drop(1)).map do |a, b|
      b.relative_position - a.relative_position
    end

    expect(gaps).to all(be > RelativePositioning::MIN_GAP)
    expect(all_issues.first.relative_position).to be > RelativePositioning::MIN_POSITION
    expect(all_issues.last.relative_position).to be < RelativePositioning::MAX_POSITION
  end
end
