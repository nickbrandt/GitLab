# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::Summary do
  let(:group) { create(:group) }
  let(:project1) { create(:project, :public, namespace: group) }
  let(:project2) { create(:project, :public, namespace: group) }
  let(:filters) { {} }

  before do
    create_vulnerabilities(1, project1, { severity: :medium, report_type: :sast })
    create_vulnerabilities(2, project2, { severity: :high, report_type: :sast })
  end

  describe '#findings_counter', :use_clean_rails_memory_store_caching do
    subject(:counter) { described_class.new(group, filters).findings_counter }

    context 'feature disabled' do
      before do
        stub_feature_flags(cache_vulnerability_summary: false)
      end

      it 'does not call Gitlab::Vulnerabilities::SummaryCache' do
        expect(Gitlab::Vulnerabilities::SummaryCache).not_to receive(:new)

        counter
      end

      it 'returns the proper format for the summary' do
        Timecop.freeze do
          expect(counter[:high]).to eq(2)
        end
      end
    end

    context 'feature enabled' do
      before do
        stub_feature_flags(cache_vulnerability_history: true)
      end

      context 'filters are passed' do
        let(:filters) { { report_type: :sast } }

        it 'does not call Gitlab::Vulnerabilities::SummaryCache' do
          expect(Gitlab::Vulnerabilities::SummaryCache).not_to receive(:new)

          counter
        end
      end

      it 'calls Gitlab::Vulnerabilities::SummaryCache' do
        expect(Gitlab::Vulnerabilities::SummaryCache).to receive(:new).twice.and_call_original

        counter
      end

      it 'returns the proper format for the summary' do
        Timecop.freeze do
          expect(counter[:high]).to eq(2)
        end
      end
    end

    def create_vulnerabilities(count, project, options = {})
      pipeline = create(:ci_pipeline, :success, project: project)

      create_list(
        :vulnerabilities_occurrence,
        count,
        report_type: options[:report_type] || :sast,
        severity:    options[:severity] || :high,
        pipelines:   [pipeline],
        project:     project,
        created_at:  options[:created_at] || Date.today
      )
    end
  end
end
