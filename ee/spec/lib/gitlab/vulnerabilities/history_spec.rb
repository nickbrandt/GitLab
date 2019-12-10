# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::History do
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

    context 'filters are passed' do
      let(:filters) { { report_type: :sast } }

      it 'does not call Gitlab::Vulnerabilities::HistoryCache' do
        expect(Gitlab::Vulnerabilities::HistoryCache).not_to receive(:new)

        counter
      end
    end

    it 'calls Gitlab::Vulnerabilities::HistoryCache' do
      expect(Gitlab::Vulnerabilities::HistoryCache).to receive(:new).twice.and_call_original

      counter
    end

    it 'returns the proper format for the history' do
      Timecop.freeze do
        expect(counter[:total]).to eq({ Date.today => 3 })
        expect(counter[:high]).to eq({ Date.today => 2 })
      end
    end

    context 'multiple projects with vulnerabilities' do
      before do
        Timecop.freeze(Date.today - 1) do
          create_vulnerabilities(1, project1, { severity: :high })
        end
        Timecop.freeze(Date.today - 4) do
          create_vulnerabilities(1, project2, { severity: :high })
        end
      end

      it 'sorts by date for each key' do
        Timecop.freeze do
          expect(counter[:high].keys).to eq([(Date.today - 4), (Date.today - 1), Date.today])
        end
      end
    end

    def create_vulnerabilities(count, project, options = {})
      report_type = options[:report_type] || :sast
      severity = options[:severity] || :high
      pipeline = create(:ci_pipeline, :success, project: project)
      created_at = options[:created_at] || Date.today
      create_list(:vulnerabilities_occurrence, count, report_type: report_type, severity: severity, pipelines: [pipeline], project: project, created_at: created_at)
    end
  end
end
