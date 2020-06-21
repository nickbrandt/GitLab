# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProcessBookkeepingService, :clean_gitlab_redis_shared_state do
  around do |example|
    described_class.with_redis do |redis|
      @redis = redis
      example.run
    end
  end

  let(:processor_class) { ::Gitlab::Elastic::BulkIndexer::IncrementalProcessor }
  let(:zset) { processor_class::REDIS_SET_KEY }
  let(:redis) { @redis }
  let(:ref_class) { ::Gitlab::Elastic::DocumentReference }

  let(:fake_refs) { Array.new(10) { |i| ref_class.new(Issue, i, "issue_#{i}", 'project_1') } }
  let(:issue) { fake_refs.first }
  let(:issue_spec) { issue.serialize }

  def track!(*items)
    described_class.track!(*items, processor: processor_class)
  end

  def queue_size
    described_class.queue_size(processor: processor_class)
  end

  describe '.track' do
    it 'enqueues a record' do
      track!(issue)

      spec, score = redis.zpopmin(zset)

      expect(spec).to eq(issue_spec)
      expect(score).to eq(1.0)
    end

    it 'enqueues a set of unique records' do
      track!(*fake_refs)

      expect(queue_size).to eq(fake_refs.size)

      spec1, score1 = redis.zpopmin(zset)
      _, score2 = redis.zpopmin(zset)

      expect(score1).to be < score2
      expect(spec1).to eq(issue_spec)
    end

    it 'enqueues 10 identical records as 1 entry' do
      track!(*([issue] * 10))

      expect(queue_size).to eq(1)
    end

    it 'deduplicates across multiple inserts' do
      10.times { track!(issue) }

      expect(queue_size).to eq(1)
    end
  end

  describe '.queue_size' do
    it 'reports the queue size' do
      expect(queue_size).to eq(0)

      track!(*fake_refs)

      expect(queue_size).to eq(fake_refs.size)

      expect { redis.zpopmin(zset) }.to change { queue_size }.by(-1)
    end
  end

  describe '.clear_tracking!' do
    it 'removes all entries from the queue' do
      track!(*fake_refs)

      expect(queue_size).to eq(fake_refs.size)

      described_class.clear_tracking!(processor: processor_class)

      expect(queue_size).to eq(0)
    end
  end

  describe '#execute' do
    let(:limit) { 5 }
    let(:processor) { processor_class.new }

    subject(:service) { described_class.new(processor) }

    before do
      stub_const("#{processor_class.name}::LIMIT", limit)
    end

    it 'submits a batch of documents' do
      track!(*fake_refs)

      expect(queue_size).to eq(fake_refs.size)
      expect_processing(*fake_refs[0...limit])

      expect { service.execute }.to change { queue_size }.by(-limit)
    end

    it 'returns the number of documents processed' do
      track!(*fake_refs)

      expect_processing(*fake_refs[0...limit])

      expect(service.execute).to eq(limit)
    end

    it 'returns 0 without writing to the index when there are no documents' do
      expect(processor).not_to receive(:flush)

      expect(service.execute).to eq(0)
    end

    it 'retries failed documents' do
      track!(*fake_refs)
      failed = fake_refs[0]

      expect(queue_size).to eq(10)
      expect_processing(*fake_refs[0...limit], failures: [failed])

      expect { service.execute }.to change { queue_size }.by(-limit + 1)

      serialized, _ = redis.zpopmax(zset)
      expect(ref_class.deserialize(serialized)).to eq(failed)
    end

    it 'discards malformed documents' do
      track!('Bad')

      expect(queue_size).to eq(1)
      expect(processor).not_to receive(:process)

      expect { service.execute }.to change { queue_size }.by(-1)
    end

    it 'fails, preserving documents, when processing fails with an exception' do
      track!(issue)

      expect(queue_size).to eq(1)
      expect(processor).to receive(:process).with(issue) { raise 'Bad' }

      expect { service.execute }.to raise_error('Bad')
      expect(queue_size).to eq(1)
    end

    def expect_processing(*refs, failures: [])
      refs.each { |ref| expect(processor).to receive(:process).with(ref) }

      expect(processor).to receive(:flush) { failures }
    end
  end
end
