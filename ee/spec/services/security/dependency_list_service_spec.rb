# frozen_string_literal: true

require 'spec_helper'

describe Security::DependencyListService do
  describe '#execute' do
    let(:project) { create :project }
    let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

    subject { described_class.new(project: project, params: params).execute }

    before do
      stub_licensed_features(dependency_list: true)
    end

    context 'without params' do
      let(:params) { {} }

      it 'returns array of data sorted by names' do
        result = subject.sort_by { |a| a[:name] }

        is_expected.to be_an(Array)
        expect(subject.size).to eq(21)
        expect(subject.first[:name]).to eq(result.first[:name])
        expect(subject.last[:name]).to eq(result.last[:name])
      end
    end

    context 'with params' do
      context 'sorted desc by types' do
        let(:params) do
          {
            sort: 'desc',
            sort_by: 'type'
          }
        end

        it 'returns array of data properly sorted' do
          result = subject.sort_by { |a| a[:type] }.reverse

          is_expected.to be_an(Array)
          expect(subject.size).to eq(21)
          expect(subject.first[:type]).to eq(result.first[:type])
          expect(subject.last[:type]).to eq(result.last[:type])
        end
      end
    end
  end
end
