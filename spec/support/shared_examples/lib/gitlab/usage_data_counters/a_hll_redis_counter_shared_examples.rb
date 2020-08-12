# frozen_string_literal: true

RSpec.shared_examples 'a hll redis usage counter' do |tracker_class|
  describe ".track_event (#{tracker_class})", :clean_gitlab_redis_shared_state do
    let(:tracker) { tracker_class.new }
    let(:known_events) { tracker.known_events }

    let(:entity1_id) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
    let(:entity2_id) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }

    around do |example|
      # We need to freeze to a reference time
      # because visits are grouped by the week number in the year
      # Without freezing the time, the test may behave inconsistently
      # depending on which day of the week test is run.
      reference_time = Time.utc(2020, 6, 1)
      Timecop.freeze(reference_time) { example.run }
    end

    it 'tracks unique events counts' do
      known_events.each do |event|
        tracker.track_event(entity1_id, event, 7.days.ago)
        tracker.track_event(entity1_id, event, 7.days.ago)
        tracker.track_event(entity2_id, event, 7.days.ago)

        tracker.track_event(entity1_id, event, 8.days.ago)

        tracker.track_event(entity1_id, event, 15.days.ago)
        tracker.track_event(entity1_id, event, 15.days.ago)
      end

      expect(tracker.unique_events(events: known_events, weeks: 4)).to eq(2)
      expect(tracker.unique_events(events: known_events, start_week: 15.days.ago, weeks: 1)).to eq(1)
      expect(tracker.unique_events(events: known_events, start_week: 30.days.ago, weeks: 1)).to eq(0)
    end

    it 'sets the keys in Redis to expire automatically after expiry' do
      known_events.each do |event|
        tracker.track_event(entity1_id, event)

        Gitlab::Redis::SharedState.with do |redis|
          redis.scan_each(match: "{#{event}}-*").each do |key|
            expect(redis.ttl(key)).to be_within(5.seconds).of(tracker.expiry)
          end
        end
      end
    end

    it 'raise an error if invalid event is given' do
      invalid_event = "x_invalid"

      expect do
        unique_visits.track_visit(entity1_id, invalid_event)
      end.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
    end
  end
end
