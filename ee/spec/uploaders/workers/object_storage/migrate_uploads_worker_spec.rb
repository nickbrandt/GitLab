# frozen_string_literal: true

require 'spec_helper'

describe ObjectStorage::MigrateUploadsWorker do
  let(:model_class) { Project }
  let(:uploads) { Upload.all }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  context 'for DesignManagement::DesignV432x230Uploader' do
    let(:model_class) { DesignManagement::Action }
    let!(:design_actions) { create_list(:design_action, 10, :with_image_v432x230) }
    let(:mounted_as) { :image_v432x230 }

    before do
      stub_uploads_object_storage(DesignManagement::DesignV432x230Uploader)
    end

    it_behaves_like 'uploads migration worker'
  end
end
