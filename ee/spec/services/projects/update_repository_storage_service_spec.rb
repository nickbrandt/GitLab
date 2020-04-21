# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include Gitlab::ShellAdapter

  subject { described_class.new(project) }

  before do
    allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
  end

  describe "#execute" do
    context 'with design repository' do
      include_examples 'moves repository to another storage', 'design' do
        let(:project) { create(:project, :repository, repository_read_only: true) }
        let(:repository) { project.design_repository }

        before do
          project.design_repository.create_if_not_exists
        end
      end
    end
  end
end
