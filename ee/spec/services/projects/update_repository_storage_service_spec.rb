# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include Gitlab::ShellAdapter

  subject { described_class.new(repository_storage_move) }

  before do
    allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
  end

  describe "#execute" do
    context 'with design repository' do
      include_examples 'moves repository to another storage', 'design' do
        let(:project) { create(:project, :repository, repository_read_only: true) }
        let(:repository) { project.design_repository }
        let(:destination) { 'test_second_storage' }
        let(:repository_storage_move) { create(:project_repository_storage_move, :scheduled, project: project, destination_storage_name: destination) }

        before do
          project.design_repository.create_if_not_exists
        end
      end
    end
  end
end
