# frozen_string_literal: true

require 'spec_helper'

describe GeoRepositoryDestroyWorker do
  describe '#perform' do
    it 'delegates project removal to Geo::RepositoryDestroyService' do
      project = create(:project)

      expect_any_instance_of(Geo::RepositoryDestroyService).to receive(:execute)

      described_class.new.perform(project.id, project.name, project.path, 'default')
    end
  end
end
