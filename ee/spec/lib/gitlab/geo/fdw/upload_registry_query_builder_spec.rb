# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Fdw::UploadRegistryQueryBuilder, :geo, :geo_fdw do
  let(:project) { create(:project) }
  let(:upload_1) { create(:upload, :issuable_upload, model: project) }
  let(:upload_2) { create(:upload, :issuable_upload, model: project) }
  let(:upload_3) { create(:upload, :issuable_upload) }
  let!(:registry_1) { create(:geo_upload_registry, file_id: upload_1.id) }
  let!(:registry_2) { create(:geo_upload_registry, :attachment, file_id: upload_2.id) }
  let!(:registry_3) { create(:geo_upload_registry, file_id: upload_3.id) }

  describe '#for_model' do
    it 'returns registries for uploads that belong to the model' do
      expect(subject.for_model(project)).to match_ids(registry_1, registry_2)
    end
  end
end
