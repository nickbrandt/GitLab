require 'spec_helper'

describe Geo::ExpireUploadsFinder, :geo do
  include EE::GeoHelpers

  let(:project) { create(:project) }

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    describe '#find_project_uploads' do
      context 'filtering per project uploads' do
        it 'returns only objects associated with the project' do
          other_upload = create(:upload, :issuable_upload)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: upload.id)
          create(:geo_file_registry, file_id: other_upload.id)

          uploads = subject.find_project_uploads(project)

          expect(uploads.count).to eq(1)
          expect(uploads.first.id).to eq(upload.id)
        end
      end

      context 'filtering replicated uploads only' do
        it 'returns only replicated or to be replicated objects' do
          create(:upload, :issuable_upload, model: project)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: upload.id, success: false)

          uploads = subject.find_project_uploads(project)

          expect(uploads.count).to eq(1)
          expect(uploads.first.id).to eq(upload.id)
        end
      end
    end

    describe '#find_file_registries_uploads' do
      context 'filtering per project uploads' do
        it 'returns only objects associated with the project' do
          other_upload = create(:upload, :issuable_upload)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: other_upload.id)
          file_registry = create(:geo_file_registry, file_id: upload.id)

          files = subject.find_file_registries_uploads(project)

          expect(files.count).to eq(1)
          expect(files.first.id).to eq(file_registry.id)
        end
      end
    end
  end

  context 'Legacy' do
    before do
      stub_fdw_disabled
    end

    describe '#find_project_uploads' do
      context 'filtering per project uploads' do
        it 'returns only objects associated with the project' do
          other_upload = create(:upload, :issuable_upload)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: upload.id)
          create(:geo_file_registry, file_id: other_upload.id)

          uploads = subject.find_project_uploads(project)

          expect(uploads.count).to eq(1)
          expect(uploads.first.id).to eq(upload.id)
        end
      end

      context 'filtering replicated uploads only' do
        it 'returns only replicated or to be replicated objects' do
          create(:upload, :issuable_upload, model: project)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: upload.id, success: false)

          uploads = subject.find_project_uploads(project)

          expect(uploads.count).to eq(1)
          expect(uploads.first.id).to eq(upload.id)
        end
      end
    end

    describe '#find_file_registries_uploads' do
      context 'filtering per project uploads' do
        it 'returns only objects associated with the project' do
          other_upload = create(:upload, :issuable_upload)
          upload = create(:upload, :issuable_upload, model: project)
          create(:geo_file_registry, file_id: other_upload.id)
          file_registry = create(:geo_file_registry, file_id: upload.id)

          files = subject.find_file_registries_uploads(project)

          expect(files.count).to eq(1)
          expect(files.first.id).to eq(file_registry.id)
        end
      end
    end
  end
end
