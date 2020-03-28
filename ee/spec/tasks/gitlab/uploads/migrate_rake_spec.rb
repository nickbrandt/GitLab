# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:uploads:migrate and migrate_to_local rake tasks' do
  let(:batch_size) { 3 }

  before do
    stub_env('MIGRATION_BATCH_SIZE', batch_size.to_s)
    stub_uploads_object_storage(uploader_class)
    Rake.application.rake_require 'tasks/gitlab/uploads/migrate'

    allow(ObjectStorage::MigrateUploadsWorker).to receive(:perform_async)
  end

  context "for DesignManagement::DesignV432x230Uploader" do
    let(:uploader_class) { DesignManagement::DesignV432x230Uploader }
    let(:model_class) {  DesignManagement::Action }
    let(:mounted_as) { :image_v432x230 }

    before do
      create_list(:design_action, 10, :with_image_v432x230)
    end

    it_behaves_like 'enqueue upload migration jobs in batch', batch: 4
  end
end
