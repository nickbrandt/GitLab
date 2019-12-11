# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::RollbackRepositoryService, :clean_gitlab_redis_shared_state do
  include GitHelpers

  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project) { create(:project, :repository, :wiki_repo, :design_repo, storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository]) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }
  let(:old_disk_path) { hashed_storage.disk_path }
  let(:new_disk_path) { legacy_storage.disk_path }

  subject(:service) { described_class.new(project: project, old_disk_path: project.disk_path) }

  describe '#execute' do
    before do
      allow(service).to receive(:gitlab_shell) { gitlab_shell }
    end

    context 'when succeeds' do
      it 'renames project, wiki and design repositories' do
        service.execute

        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.git")).to be_truthy
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.wiki.git")).to be_truthy
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.design.git")).to be_truthy
      end

      it 'updates project to be legacy and not read-only' do
        service.execute

        expect(project.legacy_storage?).to be_truthy
        expect(project.repository_read_only).to be_falsey
      end

      it 'move operation is called for each repository' do
        expect_move_repository(old_disk_path, new_disk_path)
        expect_move_repository("#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
        expect_move_repository("#{old_disk_path}.design", "#{new_disk_path}.design")

        service.execute
      end
    end

    context 'when one move fails' do
      it 'rolls repositories back to original name' do
        allow(service).to receive(:move_repository).and_call_original
        allow(service).to receive(:move_repository).with(old_disk_path, new_disk_path).once { false } # will disable first move only

        expect(service).to receive(:rollback_folder_move).and_call_original

        service.execute

        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.git")).to be_falsey
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.wiki.git")).to be_falsey
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_disk_path}.design.git")).to be_falsey
        expect(project.repository_read_only?).to be_falsey
      end

      context 'when rollback fails' do
        before do
          gitlab_shell.mv_repository(project.repository_storage, old_disk_path, new_disk_path)
        end

        it 'does not try to move nil repository over existing' do
          expect(gitlab_shell).not_to receive(:mv_repository).with(project.repository_storage, old_disk_path, new_disk_path)
          expect_move_repository("#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
          expect_move_repository("#{old_disk_path}.design", "#{new_disk_path}.design")

          service.execute
        end
      end
    end

    def expect_move_repository(from_name, to_name)
      expect(gitlab_shell).to receive(:mv_repository).with(project.repository_storage, from_name, to_name).and_call_original
    end
  end
end
