# frozen_string_literal: true

require 'spec_helper'

describe Projects::AfterRenameService do
  describe '#execute' do
    context 'when running on a primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      let(:project) { create(:project, :repository, :legacy_storage) }
      let!(:path_before_rename) { project.path }
      let!(:full_path_before_rename) { project.full_path }
      let(:path_after_rename) { "#{project.path}-renamed" }

      it 'logs the Geo::RepositoryRenamedEvent for project backed by hashed storage' do
        expect { service_execute }.to change(Geo::RepositoryRenamedEvent, :count)
      end

      it 'logs the Geo::RepositoryRenamedEvent for project backed by legacy storage' do
        expect(Geo::RepositoryRenamedEventStore)
          .to receive(:new)
          .with(
            project,
            old_path: path_before_rename,
            old_path_with_namespace: full_path_before_rename
          )
          .and_call_original

        expect { service_execute }
          .to change(Geo::RepositoryRenamedEvent, :count).by(1)
      end
    end
  end

  def service_execute
    # AfterRenameService is called by UpdateService after a successful model.update
    # the initialization will include before and after paths values
    project.update(path: path_after_rename)

    described_class.new(project, path_before: path_before_rename, full_path_before: full_path_before_rename).execute
  end
end
