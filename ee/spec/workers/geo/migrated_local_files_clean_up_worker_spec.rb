# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::MigratedLocalFilesCleanUpWorker, :geo, :geo_fdw, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:secondary) { create(:geo_node, :local_storage_only) }

  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }
  let(:project_broken_storage) { create(:project, :broken_storage) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
  end

  it 'does not run when node is disabled' do
    secondary.update_column(:enabled, false)

    expect(subject).not_to receive(:try_obtain_lease)

    subject.perform
  end

  it 'does not run when sync_object_storage is enabled' do
    secondary.update_column(:sync_object_storage, true)

    expect(subject).not_to receive(:try_obtain_lease)

    subject.perform
  end

  context 'with attachments' do
    let(:avatar_upload) { create(:upload) }
    let(:personal_snippet_upload) { create(:upload, :personal_snippet_upload) }
    let(:issuable_upload) { create(:upload, :issuable_upload) }
    let(:namespace_upload) { create(:upload, :namespace_upload) }
    let(:attachment_upload) { create(:upload, :attachment_upload) }
    let(:favicon_upload) { create(:upload, :favicon_upload) }

    before do
      create(:geo_upload_registry, :avatar, file_id: avatar_upload.id)
      create(:geo_upload_registry, :personal_file, file_id: personal_snippet_upload.id)
      create(:geo_upload_registry, :file, file_id: issuable_upload.id)
      create(:geo_upload_registry, :namespace_file, file_id: namespace_upload.id)
      create(:geo_upload_registry, :attachment, file_id: attachment_upload.id)
      create(:geo_upload_registry, :favicon, file_id: favicon_upload.id)
    end

    it 'schedules nothing for attachments stored locally' do
      expect(subject).not_to receive(:schedule_job).with(anything, avatar_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, personal_snippet_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, issuable_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, namespace_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, attachment_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, favicon_upload.id)

      subject.perform
    end

    context 'attachments stored remotely' do
      before do
        stub_uploads_object_storage(AvatarUploader)
        stub_uploads_object_storage(PersonalFileUploader)
        stub_uploads_object_storage(FileUploader)
        stub_uploads_object_storage(NamespaceFileUploader)
        stub_uploads_object_storage(AttachmentUploader)
        stub_uploads_object_storage(FaviconUploader)

        avatar_upload.update_column(:store, FileUploader::Store::REMOTE)
        personal_snippet_upload.update_column(:store, FileUploader::Store::REMOTE)
        issuable_upload.update_column(:store, FileUploader::Store::REMOTE)
        namespace_upload.update_column(:store, FileUploader::Store::REMOTE)
        attachment_upload.update_column(:store, FileUploader::Store::REMOTE)
        favicon_upload.update_column(:store, FileUploader::Store::REMOTE)
      end

      it 'schedules workers for uploads stored remotely and synced locally' do
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('avatar', avatar_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('personal_file', personal_snippet_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('file', issuable_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('namespace_file', namespace_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('attachment', attachment_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('favicon', favicon_upload.id)

        subject.perform
      end

      context 'with selective sync by namespace' do
        let(:issuable_upload_synced_group) { create(:upload, :issuable_upload, model: synced_project) }

        let(:secondary) { create(:geo_node, :local_storage_only, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        before do
          create(:geo_upload_registry, :file, file_id: issuable_upload_synced_group.id)

          issuable_upload_synced_group.update_column(:store, FileUploader::Store::REMOTE)
        end

        it 'schedules workers for uploads stored remotely and synced locally' do
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('file', issuable_upload_synced_group.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('favicon', favicon_upload.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('personal_file', personal_snippet_upload.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('attachment', attachment_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('avatar', avatar_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('file', issuable_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('namespace_file', namespace_upload.id)

          subject.perform
        end
      end

      context 'with selective sync by shard' do
        let(:issuable_upload_synced_group) { create(:upload, :issuable_upload, model: project_broken_storage) }

        let(:secondary) { create(:geo_node, :local_storage_only, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        before do
          create(:geo_upload_registry, :file, file_id: issuable_upload_synced_group.id)

          issuable_upload_synced_group.update_column(:store, FileUploader::Store::REMOTE)
        end

        it 'schedules workers for uploads stored remotely and synced locally' do
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('file', issuable_upload_synced_group.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('favicon', favicon_upload.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('personal_file', personal_snippet_upload.id)
          expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('attachment', attachment_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('avatar', avatar_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('file', issuable_upload.id)
          expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with('namespace_file', namespace_upload.id)

          subject.perform
        end
      end
    end
  end

  context 'with job artifacts' do
    let(:job_artifact_local) { create(:ci_job_artifact) }
    let(:job_artifact_remote_1) { create(:ci_job_artifact, :remote_store, project: synced_project) }

    before do
      stub_artifacts_object_storage

      create(:geo_job_artifact_registry, artifact_id: job_artifact_local.id)
      create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_1.id)
    end

    it 'schedules worker for artifact stored remotely and synced locally' do
      expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('job_artifact', job_artifact_remote_1.id)
      expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_local.id)

      subject.perform
    end

    context 'with selective sync by namespace' do
      let(:job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: project_broken_storage) }

      let(:secondary) { create(:geo_node, :local_storage_only, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)
      end

      it 'schedules worker for artifact stored remotely and synced locally' do
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('job_artifact', job_artifact_remote_2.id)
        expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_remote_1.id)
        expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_local.id)

        subject.perform
      end
    end

    context 'with selective sync by shard' do
      let(:job_artifact_remote_2) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }

      let(:secondary) { create(:geo_node, :local_storage_only, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_2.id)
      end

      it 'schedules worker for artifact stored remotely and synced locally' do
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('job_artifact', job_artifact_remote_1.id)
        expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_remote_2.id)
        expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_local.id)

        subject.perform
      end
    end
  end

  context 'backoff time' do
    let(:cache_key) { "#{described_class.name.underscore}:skip" }

    before do
      stub_uploads_object_storage(AvatarUploader)

      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:write).and_call_original
    end

    it 'sets the back off time when there are no pending items' do
      expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

      subject.perform
    end

    it 'does not perform Geo::FileRegistryRemovalWorker when the backoff time is set' do
      create(:geo_upload_registry, :avatar)

      expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

      expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async)

      subject.perform
    end
  end
end
