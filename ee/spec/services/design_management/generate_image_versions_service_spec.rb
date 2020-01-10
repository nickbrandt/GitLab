# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::GenerateImageVersionsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:version) { create(:design, :with_lfs_file, issue: issue).versions.first }
  let_it_be(:action) { version.actions.first }

  describe '#execute' do
    it 'validates the `sizes` argument' do
      sizes = DesignManagement::DesignUploader.versions.keys + [:foo]

      expect do
        described_class.new(version, sizes: sizes).execute
      end.to raise_error(ArgumentError, 'Invalid sizes: foo')
    end

    it 'allows the caller to specify which `sizes` to generate images for' do
      instance = described_class.new(version, sizes: [:foo])

      expect(instance.send(:sizes)).to eq([:foo])
    end

    it 'defaults the `sizes` argument to all versions when omitted' do
      instance = described_class.new(version)

      expect(instance.send(:sizes)).to eq(DesignManagement::DesignUploader.versions.keys)
    end

    it 'generates image versions' do
      expect { described_class.new(version).execute }
        .to change { action.reload.file.v432x230&.file }
        .from(nil).to(CarrierWave::SanitizedFile)
    end

    it 'skips genenerating image versions if the design extension is unsupported' do
      action.design.update(filename: 'foo.svg')
      described_class.new(version).execute

      expect(action.reload.file.v432x230.file).to eq(nil)
    end

    it 'records the file in uploads' do
      expect { described_class.new(version).execute }.to change { Upload.count }.by(2)

      upload = Upload.last

      aggregate_failures do
        expect(upload.model).to eq(action)
        expect(upload.uploader).to eq(DesignManagement::DesignUploader.name)
      end
    end

    it 'returns the status' do
      result = described_class.new(version).execute

      expect(result[:status]).to eq(:success)
    end

    it 'returns the version' do
      result = described_class.new(version).execute

      expect(result[:version]).to eq(version)
    end

    it 'logs if the raw image cannot be found' do
      version.designs.first.update(filename: 'foo.png')

      expect(Gitlab::AppLogger).to receive(:error).with("No design file found for Action: #{action.id}")

      described_class.new(version).execute
    end

    it 'logs if an error is encountered when generating the image versions' do
      expect_next_instance_of(DesignManagement::DesignUploader) do |uploader|
        expect(uploader).to receive(:cache!).and_raise(StandardError, 'foo')
      end

      expect(Gitlab::AppLogger).to receive(:error).with('foo')

      described_class.new(version).execute
    end
  end
end
