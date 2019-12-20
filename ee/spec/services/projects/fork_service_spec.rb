# frozen_string_literal: true
require 'spec_helper'

# This spec lives in `ee/` since moving shards is an EE-only feature.
describe Projects::ForkService do
  include ProjectForksHelper

  context 'when a project is already forked' do
    it 'creates a new poolresository after the project is moved to a new shard' do
      project = create(:project, :public, :repository)
      fork_before_move = fork_project(project)

      # Stub everything required to move a project to a Gitaly shard that does not exist
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w(default test_second_storage))
      allow_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror).and_return(true)

      Projects::UpdateRepositoryStorageService.new(project).execute('test_second_storage')
      fork_after_move = fork_project(project)
      pool_repository_before_move = PoolRepository.joins(:shard)
                                      .where(source_project: project, shards: { name: 'default' }).first
      pool_repository_after_move = PoolRepository.joins(:shard)
                                     .where(source_project: project, shards: { name: 'test_second_storage' }).first

      expect(fork_before_move.pool_repository).to eq(pool_repository_before_move)
      expect(fork_after_move.pool_repository).to eq(pool_repository_after_move)
    end
  end
end
