# frozen_string_literal: true

require 'spec_helper'

describe Projects::HashedStorage::MigrateRepositoryService do
  include EE::GeoHelpers

  let(:gitlab_shell) { Gitlab::Shell.new }
  let(:project) { create(:project, :empty_repo, :wiki_repo, :design_repo, :legacy_storage) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }
  let(:old_disk_path) { legacy_storage.disk_path }
  let(:new_disk_path) { hashed_storage.disk_path }

  subject(:service) { described_class.new(project: project, old_disk_path: old_disk_path) }

  describe '#execute' do
    context 'when a project has a design repository' do
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

        it 'move operation is called for each repository' do
          expect_move_repository(old_disk_path, new_disk_path)
          expect_move_repository("#{old_disk_path}.wiki", "#{new_disk_path}.wiki")
          expect_move_repository("#{old_disk_path}.design", "#{new_disk_path}.design")

          service.execute
        end
      end

      context 'when one move fails' do
        it 'rollsback repositories to original name' do
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

    context 'when running on a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
      end

      it 'creates a Geo::HashedStorageMigratedEvent on success' do
        expect { service.execute }.to change(Geo::EventLog, :count).by(1)

        event = Geo::EventLog.first.event

        expect(event).to be_a(Geo::HashedStorageMigratedEvent)
        expect(event).to have_attributes(
          old_storage_version: nil,
          new_storage_version: ::Project::HASHED_STORAGE_FEATURES[:repository],
          old_disk_path: legacy_storage.disk_path,
          new_disk_path: hashed_storage.disk_path,
          old_wiki_disk_path: legacy_storage.disk_path + '.wiki',
          new_wiki_disk_path: hashed_storage.disk_path + '.wiki'
        )
      end

      it 'does not create a Geo event on failure' do
        from_name = project.disk_path
        to_name = hashed_storage.disk_path

        allow(service).to receive(:move_repository).and_call_original
        allow(service).to receive(:move_repository).with(from_name, to_name).once { false } # will disable first move only

        expect { service.execute }.not_to change { Geo::EventLog.count }
      end
    end
  end
end
