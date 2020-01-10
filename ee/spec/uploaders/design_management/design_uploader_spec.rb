# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::DesignUploader do
  let(:model) { create(:design, :with_lfs_file).actions.first }
  let(:upload) { create(:upload, :design_action_upload, model: model) }

  subject(:uploader) { described_class.new(model, :file) }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/design_management/action/file/],
                  upload_path: %r[uploads/-/system/design_management/action/file/],
                  relative_path: %r[uploads/-/system/design_management/action/file/],
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/design_management/action/file/]

  context 'object_store is REMOTE' do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[design_management/action/file/],
                    upload_path: %r[design_management/action/file/],
                    relative_path: %r[design_management/action/file/]
  end

  describe '.resize?' do
    it 'returns false when passed `nil`' do
      expect(described_class.resize?(nil)).to eq(false)
    end

    it 'returns false for unsupported extensions' do
      expect(described_class.resize?('foo.svg')).to eq(false)
    end

    it 'returns true for supported extensions' do
      expect(described_class.resize?('foo.png')).to eq(true)
    end
  end

  describe '#store!' do
    let_it_be(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

    it 'does not store the file when called on the main uploader' do
      uploader.store!(file)

      expect(uploader.file).to eq(nil)
    end

    context 'when called on a version uploader instance' do
      it 'stores the file' do
        expect { uploader.v432x230.store!(file) }
          .to change { uploader.v432x230.file }
          .from(nil).to(kind_of(CarrierWave::SanitizedFile))
      end

      it 'does not cause the main file to be stored' do
        uploader.v432x230.store!(file)

        expect(uploader.file).to eq(nil)
      end
    end
  end

  describe 'conditional versions' do
    it 'enables the version when design file extension is supported' do
      expect(model.file.version_exists?(:v432x230)).to eq(true)
    end

    it 'does not enable the version when design file extension is unsupported' do
      model.design.update!(filename: 'foo.svg')

      expect(model.file.version_exists?(:v432x230)).to eq(false)
    end
  end
end
