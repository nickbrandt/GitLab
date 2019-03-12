# frozen_string_literal: true

require 'spec_helper'

describe Geo::UploadRegistry, :geo do
  set(:lfs_registry) { create(:geo_file_registry, :lfs) }
  set(:attachment_registry) { create(:geo_file_registry, :attachment, :with_file) }
  set(:avatar_registry) { create(:geo_file_registry, :avatar) }
  set(:file_registry) { create(:geo_file_registry, :file) }
  set(:namespace_file_registry) { create(:geo_file_registry, :namespace_file) }
  set(:personal_file_registry) { create(:geo_file_registry, :personal_file) }
  set(:favicon_registry) { create(:geo_file_registry, :favicon) }
  set(:import_export_registry) { create(:geo_file_registry, :import_export) }

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
end
