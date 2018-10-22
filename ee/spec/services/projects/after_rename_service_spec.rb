# frozen_string_literal: true

require 'spec_helper'

describe Projects::AfterRenameService do
  describe '#execute' do
    context 'when running on a primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      let(:project) { create(:project, :repository, :legacy_storage) }
      let(:gitlab_shell) { Gitlab::Shell.new }

      it 'logs the Geo::RepositoryRenamedEvent for project backed by hashed storage' do
        project_hashed_storage = create(:project)

        allow(project_hashed_storage)
          .to receive(:gitlab_shell)
          .and_return(gitlab_shell)

        allow(project_hashed_storage)
          .to receive(:previous_changes)
          .and_return('path' => ['foo'])

        allow(project_hashed_storage)
          .to receive(:path_was)
          .and_return('foo')

        allow(gitlab_shell)
          .to receive(:mv_repository)
          .twice.and_return(true)

        expect { described_class.new(project_hashed_storage).execute }
          .to change(Geo::RepositoryRenamedEvent, :count)
      end

      it 'logs the Geo::RepositoryRenamedEvent for project backed by legacy storage' do
        allow(project)
          .to receive(:gitlab_shell)
          .and_return(gitlab_shell)

        allow(project)
          .to receive(:previous_changes)
          .and_return('path' => ['foo'])

        allow(project)
          .to receive(:path_was)
          .and_return('foo')

        allow(gitlab_shell)
          .to receive(:mv_repository)
          .twice.and_return(true)

        expect(Geo::RepositoryRenamedEventStore)
          .to receive(:new)
          .with(
            project,
            old_path: 'foo',
            old_path_with_namespace: "#{project.namespace.full_path}/foo"
          )
          .and_call_original

        expect { described_class.new(project).execute }
          .to change(Geo::RepositoryRenamedEvent, :count).by(1)
      end
    end
  end
end
