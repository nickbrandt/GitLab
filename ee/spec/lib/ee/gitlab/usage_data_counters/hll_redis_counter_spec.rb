# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::HLLRedisCounter, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }

  let(:default_context) { 'default' }
  let(:ultimate_context) { 'ultimate' }
  let(:gold_context) { 'gold' }
  let(:invalid_context) { 'invalid' }

  let(:context_event) { 'context_event' }
  let(:other_context_event) { 'other_context_event' }

  let(:known_events) do
    [
      { name: context_event, category: 'other', expiry: 29, aggregation: 'weekly' },
      { name: other_context_event, category: 'other', expiry: 29, aggregation: 'weekly' }
    ].map(&:with_indifferent_access)
  end

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    # Monday 6th of June
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
  end

  before do
    allow(described_class).to receive(:known_events).and_return(known_events)
  end

  describe '.track_event' do
    context 'with valid context' do
      where(:entity, :event_name, :context) do
        entity1 | context_event | default_context
        entity1 | context_event | ultimate_context
        entity1 | context_event | gold_context
      end

      with_them do
        it 'increases both conext event counter and total event counter' do
          expect(Gitlab::Redis::HLL).to receive(:add).twice

          described_class.track_event(entity, event_name, context: context)
        end
      end
    end

    context 'when sending empty context' do
      it 'increases only total event counter' do
        expect(Gitlab::Redis::HLL).to receive(:add)

        described_class.track_event(entity1, context_event, context: '')
      end
    end
  end

  describe '.unique_events' do
    before do
      described_class.track_event([entity1, entity3], context_event, context: default_context, time: 2.days.ago)
      described_class.track_event(entity3, context_event, context: ultimate_context, time: 2.days.ago)
      described_class.track_event(entity3, context_event, context: gold_context, time: 2.days.ago)
      described_class.track_event(entity3, context_event, context: invalid_context, time: 2.days.ago)
      described_class.track_event([entity1, entity2], context_event, time: 2.weeks.ago)
    end

    subject(:unique_events) { described_class.unique_events(event_names: event_names, start_date: 4.weeks.ago, end_date: Date.current, context: context) }

    context 'with correct arguments' do
      where(:event_names, :context, :value) do
        'context_event' | 'default'  | 2
        'context_event' | 'ultimate' | 1
        'context_event' | 'gold'     | 1
        'context_event' | ''         | 3
      end

      with_them do
        it { is_expected.to eq value }
      end
    end

    context 'with empty invalid context' do
      it 'raise error' do
        expect { described_class.unique_events(event_names: 'context_event', start_date: 4.weeks.ago, end_date: Date.current, context: invalid_context) }.to raise_error('Invalid context')
      end
    end
  end
end
