# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::UniqueVisits, :clean_gitlab_redis_shared_state do
  let(:unique_visits) { Gitlab::Analytics::UniqueVisits.new }
  let(:target1_id) { 'g_analytics_contribution' }
  let(:target2_id) { 'g_analytics_insights' }
  let(:target3_id) { 'g_analytics_issues' }
  let(:visitor1_id) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:visitor2_id) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:visitor3_id) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    reference_time = Time.utc(2020, 6, 1)
    Timecop.freeze(reference_time) { example.run }
  end

  describe '#track_visit' do
    it 'tracks the unique weekly visits for targets' do
      known_events = ::Gitlab::Analytics::UniqueVisits::KNOWN_EVENTS

      unique_visits.track_visit(visitor1_id, target1_id, 7.days.ago)
      unique_visits.track_visit(visitor1_id, target1_id, 7.days.ago)
      unique_visits.track_visit(visitor2_id, target1_id, 7.days.ago)

      unique_visits.track_visit(visitor2_id, target2_id, 7.days.ago)
      unique_visits.track_visit(visitor1_id, target2_id, 8.days.ago)
      unique_visits.track_visit(visitor1_id, target2_id, 15.days.ago)

      expect(unique_visits.unique_visits_for(targets: target1_id)).to eq(2)
      expect(unique_visits.unique_visits_for(targets: target2_id)).to eq(1)

      expect(unique_visits.unique_visits_for(targets: target2_id, start_week: 15.days.ago)).to eq(1)

      expect(unique_visits.unique_visits_for(targets: target3_id)).to eq(0)

      expect(unique_visits.unique_visits_for(targets: known_events)).to eq(2)
      expect(unique_visits.unique_visits_for(targets: known_events, start_week: 15.days.ago)).to eq(1)
      expect(unique_visits.unique_visits_for(targets: known_events, start_week: 30.days.ago)).to eq(0)

      expect(unique_visits.unique_visits_for(targets: known_events, weeks: 4)).to eq(2)
    end

    it_behaves_like 'a hll redis usage counter', Gitlab::Analytics::UniqueVisits
  end
end
