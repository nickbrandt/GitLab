# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::History do
  describe '#findings_counter', :use_clean_rails_memory_store_caching do
    shared_examples 'the history cache when given an expected Vulnerable' do
      let(:filters) { project_ids }
      let(:today) { Date.parse('20191031') }

      before do
        Timecop.freeze(today) do
          create_vulnerabilities(1, project1, { severity: :medium, report_type: :sast })
          create_vulnerabilities(2, project2, { severity: :high, report_type: :sast })
        end
      end

      subject(:counter) { described_class.new(vulnerable, params: filters).findings_counter }

      context 'when filters are passed' do
        let(:filters) { project_ids.merge(report_type: :sast) }

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
        Timecop.freeze(today) do
          expect(counter[:total]).to eq({ today => 3 })
          expect(counter[:high]).to eq({ today => 2 })
        end
      end

      context 'when there are multiple projects with vulnerabilities' do
        before do
          Timecop.freeze(today - 1) do
            create_vulnerabilities(1, project1, { severity: :high })
          end
          Timecop.freeze(today - 4) do
            create_vulnerabilities(1, project2, { severity: :high })
          end
        end

        it 'sorts by date for each key' do
          Timecop.freeze(today) do
            expect(counter[:high].keys).to eq([(today - 4), (today - 1), today])
          end
        end
      end

      def create_vulnerabilities(count, project, options = {})
        report_type = options[:report_type] || :sast
        severity = options[:severity] || :high
        pipeline = create(:ci_pipeline, :success, project: project)
        created_at = options[:created_at] || today
        create_list(:vulnerabilities_occurrence, count, report_type: report_type, severity: severity, pipelines: [pipeline], project: project, created_at: created_at)
      end
    end

    context 'when the given vulnerable is a Group' do
      it_behaves_like 'the history cache when given an expected Vulnerable' do
        let(:group) { create(:group) }
        let(:project1) { create(:project, :public, namespace: group) }
        let(:project2) { create(:project, :public, namespace: group) }
        let(:project_ids) { {} }
        let(:vulnerable) { group }
      end
    end

    context 'when given an ApplicationInstance' do
      let(:vulnerable) { ApplicationInstance.new }

      context 'and a project_id filter' do
        it_behaves_like 'the history cache when given an expected Vulnerable' do
          let(:group) { create(:group) }
          let(:project1) { create(:project, :public, namespace: group) }
          let(:project2) { create(:project, :public, namespace: group) }
          let(:project_ids) { ActionController::Parameters.new({ 'project_id' => [project1, project2] }) }
        end
      end

      context 'and no project_id filter' do
        it 'throws an error saying that the filter must be given' do
          expect { described_class.new(vulnerable, params: {}).findings_counter }.to raise_error(
            Gitlab::Vulnerabilities::History::NoProjectIDsError,
            "A project_id filter must be given with this #{vulnerable.model_name.human.downcase}"
          )
        end
      end
    end
  end
end
