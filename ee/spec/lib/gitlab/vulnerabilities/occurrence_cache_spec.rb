# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::OccurrenceCache do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user) { create :user }
  let(:project_cache_key) { described_class.new(group, project.id, user).send(:cache_key) }
  let(:vulnerabilities) { create_vulnerabilities(1, project) }

  before do
    vulnerabilities
    group.add_owner(user)
  end

  describe '#fetch', :use_clean_rails_memory_store_caching do
    it 'reads from cache when records are cached' do
      occurrence_cache = described_class.new(group, project.id, user)

      expect(Rails.cache.fetch(project_cache_key, raw: true)).to be_nil

      control_count = ActiveRecord::QueryRecorder.new { occurrence_cache.fetch }

      expect { 2.times { occurrence_cache.fetch } }.not_to exceed_query_limit(control_count)
    end

    it 'returns the proper format for uncached occurrence' do
      fetched = described_class.new(group, project.id, user).fetch

      expect(fetched).to be_an Array
      expect(fetched.first).to be_a Hash
      expect(fetched.count).to eq 1
      expect(fetched.first['id']).to eq vulnerabilities.first.id
    end

    it 'returns the proper format for cached summary' do
      described_class.new(group, project.id, user).fetch
      fetched = described_class.new(group, project.id, user).fetch

      expect(fetched).to be_an Array
      expect(fetched.first).to be_a Hash
      expect(fetched.count).to eq 1
      expect(fetched.first['id']).to eq vulnerabilities.first.id
    end

    def create_vulnerabilities(count, project, options = {})
      pipeline = create(:ci_pipeline, :success, project: project)

      create_list(
        :vulnerabilities_occurrence,
        count,
        report_type: options[:report_type] || :sast,
        pipelines:   [pipeline],
        project:     project
      )
    end
  end
end
