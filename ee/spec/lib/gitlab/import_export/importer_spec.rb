# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Importer do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:test_path) { "#{Dir.tmpdir}/importer_spec" }
    let(:shared) { project.import_export_shared }
    let(:import_file) { fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz') }

    subject(:importer) { described_class.new(project) }

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(test_path)
      end
      allow_next_instance_of(Gitlab::ImportExport::FileImporter) do |instance|
        allow(instance).to receive(:remove_import_file)
      end
      stub_uploads_object_storage(FileUploader)

      FileUtils.mkdir_p(shared.export_path)
      ImportExportUpload.create(project: project, import_file: import_file)
    end

    after do
      FileUtils.rm_rf(test_path)
    end

    it 'restores the design repo' do
      expect(Gitlab::ImportExport::DesignRepoRestorer).to receive(:new).and_call_original

      importer.execute
    end
  end
end
