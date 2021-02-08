# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::ErrorTracking::Processor::ApplicationContextProcessor do
  subject(:processor) { described_class.new }

  before do
    allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')
    allow(I18n).to receive(:locale).and_return('en')
  end

  context 'user metadata' do
    let(:user) { create(:user) }

    context 'when event user metadata was not set' do
      it 'appends username to the event metadata' do
        event = {}

        Gitlab::ApplicationContext.with_context(user: user) do
          processor.process(event)
        end

        expect(event[:user]).to eql(
          username: user.username
        )
      end
    end

    context 'when event user metadata was already set' do
      it 'appends username to the event metadata' do
        event = {
          user: {
            ip_address: '127.0.0.1'
          }
        }

        Gitlab::ApplicationContext.with_context(user: user) do
          processor.process(event)
        end

        expect(event[:user]).to eql(
          ip_address: '127.0.0.1',
          username: user.username
        )
      end
    end
  end

  context 'tags metadata' do
    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is not set' do
      before do
        stub_env('GITLAB_SENTRY_EXTRA_TAGS', nil)
      end

      it 'does not log into AppLogger' do
        expect(Gitlab::AppLogger).not_to receive(:debug)
      end

      it 'does not send any extra tags' do
        event = {}

        Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
          processor.process(event)
        end

        expect(event[:tags]).to eql(
          correlation_id: 'cid',
          locale: 'en',
          program: 'test',
          feature_category: 'feature_a'
        )
      end
    end

    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is a JSON hash' do
      it 'includes those tags in all events' do
        stub_env('GITLAB_SENTRY_EXTRA_TAGS', { foo: 'bar', baz: 'quux' }.to_json)

        event = {}

        Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
          processor.process(event)
        end

        expect(event[:tags]).to eql(
          correlation_id: 'cid',
          locale: 'en',
          program: 'test',
          feature_category: 'feature_a',
          'foo' => 'bar',
          'baz' => 'quux'
        )
      end

      it 'does not log into AppLogger' do
        expect(Gitlab::AppLogger).not_to receive(:debug)
      end
    end

    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is not a JSON hash' do
      using RSpec::Parameterized::TableSyntax

      where(:env_var, :error) do
        { foo: 'bar', baz: 'quux' }.inspect | 'JSON::ParserError'
        [].to_json | 'NoMethodError'
        [%w[foo bar]].to_json | 'NoMethodError'
        %w[foo bar].to_json | 'NoMethodError'
        '"string"' | 'NoMethodError'
      end

      with_them do
        before do
          stub_env('GITLAB_SENTRY_EXTRA_TAGS', env_var)
        end

        it 'logs into AppLogger' do
          expect(Gitlab::AppLogger).to receive(:debug).with(a_string_matching(error))

          processor.process({})
        end

        it 'does not include any extra tags' do
          event = {}

          Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
            processor.process(event)
          end

          expect(event[:tags]).to eql(
            correlation_id: 'cid',
            locale: 'en',
            program: 'test',
            feature_category: 'feature_a'
          )
        end
      end
    end
  end
end
