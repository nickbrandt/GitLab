# frozen_string_literal: true

require 'spec_helper'

describe Geo::DesignRepositorySyncWorker, :geo do
  describe '#perform' do
    it 'runs DesignRepositorySyncService' do
      project = create(:project)
      service = spy(:service)

      expect(Geo::DesignRepositorySyncService).to receive(:new).with(project).and_return(service)

      described_class.new.perform(project.id)

      expect(service).to have_received(:execute)
    end

    it 'does not run DesignRepositorySyncService if feature is disabled' do
      project = create(:project)

      stub_feature_flags(enable_geo_design_sync: false)

      expect(Geo::DesignRepositorySyncService).not_to receive(:new)

      described_class.new.perform(project.id)
    end

    it 'logs error when repository does not exist' do
      worker = described_class.new

      expect(worker).to receive(:log_error)
        .with("Couldn't find project, skipping syncing", project_id: 20)

      expect(Geo::DesignRepositorySyncService).not_to receive(:new)

      worker.perform(20)
    end
  end
end
