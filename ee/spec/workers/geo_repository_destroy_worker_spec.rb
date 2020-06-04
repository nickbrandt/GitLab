# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoRepositoryDestroyWorker do
  describe '#perform' do
    it 'delegates project removal to Geo::RepositoryDestroyService' do
      project = create(:project)

      expect_next_instance_of(Geo::RepositoryDestroyService) do |instance|
        expect(instance).to receive(:execute)
      end

      described_class.new.perform(project.id, project.name, project.path, 'default')
    end
  end
end
