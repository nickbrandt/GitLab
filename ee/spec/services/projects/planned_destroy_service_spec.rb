# frozen_string_literal: true

require 'spec_helper'

describe Projects::PlannedDestroyService do
  let(:user) { create(:user)}
  let(:project) { create(:project, :repository, deleting_user: user, namespace: user.namespace) }
  let(:path) do
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      project.repository.path_to_repo
    end
  end

  describe '#execute' do
    it 'deletes the project' do
      described_class.new(project, user).execute

      expect(Project.all).not_to include(project)
      expect(Dir.exist?(path)).to be_falsey
    end
  end
end
