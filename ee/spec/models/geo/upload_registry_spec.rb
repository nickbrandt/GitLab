# frozen_string_literal: true

require 'spec_helper'

describe Geo::UploadRegistry, :geo, :geo_fdw do
  let!(:lfs_registry) { create(:geo_file_registry, :lfs) }
  let!(:attachment_registry) { create(:geo_file_registry, :attachment, :with_file) }
  let!(:avatar_registry) { create(:geo_file_registry, :avatar) }
  let!(:file_registry) { create(:geo_file_registry, :file) }
  let!(:namespace_file_registry) { create(:geo_file_registry, :namespace_file) }
  let!(:personal_file_registry) { create(:geo_file_registry, :personal_file) }
  let!(:favicon_registry) { create(:geo_file_registry, :favicon) }
  let!(:import_export_registry) { create(:geo_file_registry, :import_export) }

  it 'finds all upload registries' do
    expected = [attachment_registry,
                avatar_registry,
                file_registry,
                namespace_file_registry,
                personal_file_registry,
                favicon_registry,
                import_export_registry]

    expect(described_class.all).to match_ids(expected)
  end

  it 'finds associated Upload record' do
    expect(described_class.find(attachment_registry.id).upload).to be_an_instance_of(Upload)
  end

  describe '.with_search' do
    it 'searches registries on path' do
      upload = create(:upload, path: 'uploads/-/system/project/avatar/my-awesome-avatar.png')
      upload_registry = create(:geo_upload_registry, file_id: upload.id, file_type: :avatar)

      expect(described_class.with_search('awesome-avatar')).to match_ids(upload_registry)
    end
  end

  describe '#file' do
    it 'returns the path of the upload of a registry' do
      upload = create(:upload, :with_file)
      registry = create(:geo_upload_registry, :file, file_id: upload.id)

      expect(registry.file).to eq(upload.path)
    end

    it 'return "removed" message when the upload no longer exists' do
      registry = create(:geo_upload_registry, :avatar)

      expect(registry.file).to match(/^Removed avatar with id/)
    end
  end
end
