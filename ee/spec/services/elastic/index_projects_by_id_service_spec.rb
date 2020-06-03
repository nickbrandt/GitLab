# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::IndexProjectsByIdService do
  describe '#execute' do
    it 'schedules index workers' do
      Sidekiq::Testing.fake! do
        described_class.new.execute(project_ids: [1, 2], namespace_ids: [3, 4])
      end

      jobs = Sidekiq::Queues[ElasticFullIndexWorker.queue]

      expect(jobs.size).to eq(4)
      expect(jobs[0]['args']).to eq(['index', 'Project', 1, nil])
      expect(jobs[1]['args']).to eq(['index', 'Project', 2, nil])
      expect(jobs[2]['args']).to eq([3, 'index'])
      expect(jobs[3]['args']).to eq([4, 'index'])
    end
  end
end
