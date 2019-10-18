# frozen_string_literal: true

shared_examples 'milestone_issue_counts' do
  describe '#issue_count' do
    it 'is caching the count' do
      cache_key = "milestone_#{milestone.id}_issue_#{state}_count_key"
      expect(Rails.cache).to receive(:fetch).with(cache_key)

      milestone.send("#{state}_issues_count", member)
    end
  end
end
