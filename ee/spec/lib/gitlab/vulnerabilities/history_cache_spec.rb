# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Vulnerabilities::HistoryCache do
  describe '#fetch', :use_clean_rails_memory_store_caching do
    shared_examples 'the history cache when given an expected Vulnerable' do
      let(:project) { create(:project, :public, namespace: group) }
      let(:project_cache_key) { described_class.new(vulnerable, project.id).send(:cache_key) }
      let(:today) { '1980-10-31' }

      before do
        Timecop.freeze(today) do
          create_vulnerabilities(1, project)
        end
      end

      it 'reads from cache when records are cached' do
        history_cache = described_class.new(vulnerable, project.id)

        expect(Rails.cache.fetch(project_cache_key, raw: true)).to be_nil

        control_count = ActiveRecord::QueryRecorder.new { history_cache.fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE) }

        expect { 2.times { history_cache.fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE) } }.not_to exceed_query_limit(control_count)
      end

      it 'returns the proper format for uncached history' do
        Timecop.freeze(today) do
          fetched_history = described_class.new(vulnerable, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)

          expect(fetched_history[:total]).to eq( Date.today => 1 )
          expect(fetched_history[:high]).to eq( Date.today => 1 )
        end
      end

      it 'returns the proper format for cached history' do
        Timecop.freeze(today) do
          described_class.new(vulnerable, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)
          fetched_history = described_class.new(vulnerable, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)

          expect(fetched_history[:total]).to eq( Date.today => 1 )
          expect(fetched_history[:high]).to eq( Date.today => 1 )
        end
      end

      def create_vulnerabilities(count, project, options = {})
        report_type = options[:report_type] || :sast
        pipeline = create(:ci_pipeline, :success, project: project)
        create_list(:vulnerabilities_occurrence, count, report_type: report_type, pipelines: [pipeline], project: project)
      end
    end

    context 'when given a Group' do
      it_behaves_like 'the history cache when given an expected Vulnerable' do
        let(:group) { create(:group) }
        let(:vulnerable) { group }
      end
    end

    context 'when given an InstanceSecurityDashboard' do
      it_behaves_like 'the history cache when given an expected Vulnerable' do
        let(:group) { create(:group) }
        let(:user) { create(:user) }
        let(:vulnerable) { InstanceSecurityDashboard.new(user) }

        before do
          project.add_developer(user)
          user.security_dashboard_projects << project
        end
      end
    end
  end
end
