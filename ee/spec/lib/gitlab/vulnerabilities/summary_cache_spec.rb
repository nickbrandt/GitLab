# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::SummaryCache do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:project_cachec_key) { described_class.new(group, project.id).send(:cache_key) }

  before do
    create_vulnerabilities(1, project)
  end

  describe '#fetch', :use_clean_rails_memory_store_caching do
    it 'reads from cache when records are cached' do
      summary_cache = described_class.new(group, project.id)

      expect(Rails.cache.fetch(project_cachec_key, raw: true)).to be_nil

      control_count = ActiveRecord::QueryRecorder.new { summary_cache.fetch }

      expect { 2.times { summary_cache.fetch } }.not_to exceed_query_limit(control_count)
    end

    it 'returns the proper format for uncached summary' do
      Timecop.freeze do
        fetched_history = described_class.new(group, project_id).fetch

        expect(fetched_history[:total]).to eq( Date.today => 1 )
        expect(fetched_history[:high]).to eq( Date.today => 1 )
      end
    end

    it 'returns the proper format for cached summary' do
      Timecop.freeze do
        described_class.new(group, project.id).fetch
        fetched_history = described_class.new(group, project.id).fetch

        expect(fetched_history[:total]).to eq( Date.today => 1 )
        expect(fetched_history[:high]).to eq( Date.today => 1 )
      end
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
