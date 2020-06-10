# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::Project, :geo_fdw, type: :model do
  context 'relationships' do
    it { is_expected.to have_many(:job_artifacts).class_name('Geo::Fdw::Ci::JobArtifact') }
    it { is_expected.to have_many(:container_repositories).class_name('Geo::Fdw::ContainerRepository') }
  end

  describe '.search' do
    let(:test_project) { create(:project, description: 'kitten mittens') }
    let(:project) { described_class.find(test_project.id) }

    it 'returns projects with a matching name' do
      expect(described_class.search(project.name)).to eq([project])
    end

    it 'returns projects with a partially matching name' do
      expect(described_class.search(project.name[0..2])).to eq([project])
    end

    it 'returns projects with a matching name regardless of the casing' do
      expect(described_class.search(project.name.upcase)).to eq([project])
    end

    it 'returns projects with a matching description' do
      expect(described_class.search(project.description)).to eq([project])
    end

    it 'returns projects with a partially matching description' do
      expect(described_class.search('kitten')).to eq([project])
    end

    it 'returns projects with a matching description regardless of the casing' do
      expect(described_class.search('KITTEN')).to eq([project])
    end

    it 'returns projects with a matching path' do
      expect(described_class.search(project.path)).to eq([project])
    end

    it 'returns projects with a partially matching path' do
      expect(described_class.search(project.path[0..2])).to eq([project])
    end

    it 'returns projects with a matching path regardless of the casing' do
      expect(described_class.search(project.path.upcase)).to eq([project])
    end
  end
end
