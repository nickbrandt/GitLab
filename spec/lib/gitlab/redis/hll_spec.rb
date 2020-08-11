# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::HLL, :clean_gitlab_redis_shared_state do
  describe '.add' do
    context 'when checking key format' do
      it 'raise an error when using an invalid key format' do
        expect { described_class.add(key: 'test', value: 1, expiry: 1.day) }.to raise_error(Gitlab::Redis::HLL::KeyFormatError)
        expect { described_class.add(key: 'test-{metric', value: 1, expiry: 1.day) }.to raise_error(Gitlab::Redis::HLL::KeyFormatError)
        expect { described_class.add(key: 'test-{metric}}', value: 1, expiry: 1.day) }.to raise_error(Gitlab::Redis::HLL::KeyFormatError)
      end

      it "doesn't raise error when having correct format" do
        expect { described_class.add(key: 'test-{metric}', value: 1, expiry: 1.day) }.not_to raise_error
        expect { described_class.add(key: 'test-{metric}-1', value: 1, expiry: 1.day) }.not_to raise_error
        expect { described_class.add(key: 'test:{metric}-1', value: 1, expiry: 1.day) }.not_to raise_error
        expect { described_class.add(key: '2020-216-{project_action}', value: 1, expiry: 1.day) }.not_to raise_error
        expect { described_class.add(key: 'i_{analytics}_dev_ops_score-2020-32', value: 1, expiry: 1.day) }.not_to raise_error
      end
    end
  end

  describe 'counts correct data for expand_vulnerabilities event' do
    before do
      described_class.add(key: '2020-32-{expand_vulnerabilities}', value: "user_id_1", expiry: 1.day)
      described_class.add(key: '2020-32-{expand_vulnerabilities}', value: "user_id_1", expiry: 1.day)
      described_class.add(key: '2020-32-{expand_vulnerabilities}', value: "user_id_2", expiry: 1.day)
      described_class.add(key: '2020-32-{expand_vulnerabilities}', value: "user_id_3", expiry: 1.day)

      described_class.add(key: '2020-33-{expand_vulnerabilities}', value: "user_id_3", expiry: 1.day)
      described_class.add(key: '2020-33-{expand_vulnerabilities}', value: "user_id_3", expiry: 1.day)

      described_class.add(key: '2020-34-{expand_vulnerabilities}', value: "user_id_3", expiry: 1.day)
      described_class.add(key: '2020-34-{expand_vulnerabilities}', value: "user_id_2", expiry: 1.day)
    end

    it 'has 3 distinct users for weeks 32, 33, 34' do
      expect(described_class.count(keys: ['2020-32-{expand_vulnerabilities}', '2020-33-{expand_vulnerabilities}', '2020-34-{expand_vulnerabilities}'])).to eq(3)
    end

    it 'has 3 distinct users for weeks 32, 33' do
      expect(described_class.count(keys: ['2020-32-{expand_vulnerabilities}', '2020-33-{expand_vulnerabilities}'])).to eq(3)
    end

    it 'has 2 distinct users for weeks 33, 34' do
      expect(described_class.count(keys: ['2020-33-{expand_vulnerabilities}', '2020-34-{expand_vulnerabilities}'])).to eq(2)
    end

    it 'has one distinct user for weel 33' do
      expect(described_class.count(keys: ['2020-33-{expand_vulnerabilities}'])).to eq(1)
    end

    it 'has 4 distinct users when one different user has an action on week 34' do
      described_class.add(key: '2020-34-{expand_vulnerabilities}', value: "user_id_4", expiry: 29.days)

      expect(described_class.count(keys: ['2020-32-{expand_vulnerabilities}', '2020-33-{expand_vulnerabilities}', '2020-34-{expand_vulnerabilities}'])).to eq(4)
    end
  end
end
