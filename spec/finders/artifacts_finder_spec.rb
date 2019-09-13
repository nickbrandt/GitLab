# frozen_string_literal: true

require 'spec_helper'

describe ArtifactsFinder do
  let(:project) { create(:project) }

  describe '#execute' do
    before do
      create(:ci_build, :artifacts, project: project)
    end

    subject { described_class.new(project, params).execute }

    context 'with empty params' do
      let(:params) { {} }

      it 'returns all artifacts belonging to the project' do
        expect(subject).to contain_exactly(*project.job_artifacts)
      end
    end

    context 'with sort param' do
      let(:params) { { sort: 'size_desc' } }

      it 'sorts the artifacts' do
        expect(subject).to eq(project.job_artifacts.order_by('size_desc'))
      end
    end

    context 'with job_name param' do
      let(:params) { { search: 'unique_name' } }

      it 'filters the artifacts by job name' do
        build = create(:ci_build, :artifacts, project: project, name: 'unique_name')

        expect(subject).to contain_exactly(*build.job_artifacts)
      end
    end
  end
end
