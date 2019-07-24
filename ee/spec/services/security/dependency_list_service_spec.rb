# frozen_string_literal: true

require 'spec_helper'

describe Security::DependencyListService do
  describe '#execute' do
    let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report) }

    subject { described_class.new(pipeline: pipeline, params: params).execute }

    before do
      stub_licensed_features(dependency_list: true)
    end

    context 'without params' do
      let(:params) { {} }

      it 'returns array of dependencies' do
        is_expected.to be_an(Array)
      end

      it 'is sorted by names by default' do
        expect(subject.size).to eq(21)
        expect(subject.first[:name]).to eq('async')
        expect(subject.last[:name]).to eq('xpath.js')
      end
    end

    context 'with params' do
      context 'filtered by package_managers' do
        let(:params) { { package_manager: 'bundler' } }

        it 'returns filtered items' do
          expect(subject.size).to eq(2)
          expect(subject.first[:packager]).to eq('Ruby (Bundler)')
        end
      end

      context 'sorted desc by packagers' do
        let(:params) do
          {
            sort: 'desc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:packager]).to eq('Ruby (Bundler)')
          expect(subject.last[:packager]).to eq('JavaScript (Yarn)')
        end
      end

      context 'sorted asc by packagers' do
        let(:params) do
          {
            sort: 'asc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:packager]).to eq('JavaScript (Yarn)')
          expect(subject.last[:packager]).to eq('Ruby (Bundler)')
        end
      end

      context 'sorted desc by names' do
        let(:params) do
          {
            sort: 'desc',
            sort_by: 'name'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:name]).to eq('xpath.js')
          expect(subject.last[:name]).to eq('async')
        end
      end
    end
  end
end
