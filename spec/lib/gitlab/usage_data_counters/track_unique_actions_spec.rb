# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::TrackUniqueActions, :clean_gitlab_redis_shared_state do
  subject(:track_unique_events) { described_class.new }

  def track_action(params)
    track_unique_events.track_action(params)
  end

  def count_unique_events(params)
    track_unique_events.count_unique_events(params)
  end

  describe '#tracking_event' do
    context 'when usage pings are enabled' do
      before do
        Gitlab::CurrentSettings.update!(usage_ping_enabled: true)
      end

      context 'when the feature flag is enabled ' do
        let(:time) { Time.zone.now }

        before do
          stub_feature_flags(cache_diff_stats_merge_request: true)
        end

        context 'when target is valid' do
          context 'when action is valid' do
            it 'tracks and counts the events as expected' do
              project = Event::TARGET_TYPES[:project]
              design = Event::TARGET_TYPES[:design]
              wiki = Event::TARGET_TYPES[:wiki]

              track_action(event_action: :pushed, event_target: project, author_id: 1)
              track_action(event_action: :pushed, event_target: project, author_id: 1)
              track_action(event_action: :pushed, event_target: project, author_id: 2)
              track_action(event_action: :pushed, event_target: project, author_id: 3)
              track_action(event_action: :pushed, event_target: project, author_id: 4, time: time - 3.days)
              track_action(event_action: :created, event_target: project, author_id: 5, time: time - 3.days)

              track_action(event_action: :destroyed, event_target: design, author_id: 3)
              track_action(event_action: :created, event_target: design, author_id: 4)
              track_action(event_action: :updated, event_target: design, author_id: 5)
              track_action(event_action: :pushed, event_target: design, author_id: 6)

              track_action(event_action: :destroyed, event_target: wiki, author_id: 5)
              track_action(event_action: :created, event_target: wiki, author_id: 3)
              track_action(event_action: :updated, event_target: wiki, author_id: 4)
              track_action(event_action: :pushed, event_target: wiki, author_id: 6)

              expect(count_unique_events(event_action: described_class::PUSH_ACTION, date_from: time, date_to: Date.tomorrow)).to eq(3)
              expect(count_unique_events(event_action: described_class::PUSH_ACTION, date_from: time - 5.days, date_to: Date.tomorrow)).to eq(4)
              expect(count_unique_events(event_action: described_class::DESIGN_ACTION, date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
              expect(count_unique_events(event_action: described_class::WIKI_ACTION, date_from: time - 5.days, date_to: Date.tomorrow)).to eq(3)
              expect(count_unique_events(event_action: described_class::PUSH_ACTION, date_from: time - 5.days, date_to: time - 2.days)).to eq(1)
            end
          end

          context 'when action is invalid' do
            it 'does not add any event' do
              expect(Gitlab::Redis::SharedState).not_to receive(:with)

              track_action(event_action: :test, event_target: :wiki, author_id: 2)
            end
          end
        end

        context 'when target is invalid' do
          it 'does not add any event' do
            expect(Gitlab::Redis::SharedState).not_to receive(:with)

            track_action(event_action: :pushed, event_target: :test, author_id: 2)
          end
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(cache_diff_stats_merge_request: true)
        end

        it 'does not add any event' do
          expect(Gitlab::Redis::SharedState).not_to receive(:with)

          track_action(event_action: :pushed, event_target: :project, author_id: 2)
        end
      end
    end

    context 'when usage pings are disabled' do
      before do
        Gitlab::CurrentSettings.update!(usage_ping_enabled: false)
      end

      it 'does not add any event' do
        expect(Gitlab::Redis::SharedState).not_to receive(:with)

        track_action(event_action: :pushed, event_target: :project, author_id: 2)
      end
    end
  end
end
