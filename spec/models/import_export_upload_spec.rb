# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportExportUpload do
  subject { described_class.new(project: create(:project)) }

  shared_examples 'stores the Import/Export file' do |method|
    it 'stores the import file' do
      subject.public_send("#{method}=", fixture_file_upload('spec/fixtures/project_export.tar.gz'))

      subject.save!

      url = "/uploads/-/system/import_export_upload/#{method}/#{subject.id}/project_export.tar.gz"

      expect(subject.public_send(method).url).to eq(url)
    end
  end

  context 'import' do
    it_behaves_like 'stores the Import/Export file', :import_file
  end

  context 'export' do
    it_behaves_like 'stores the Import/Export file', :export_file
  end

  describe 'scopes' do
    let_it_be(:upload1) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')) }
    let_it_be(:upload2) { create(:import_export_upload) }
    let_it_be(:upload3) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz'), updated_at: 25.hours.ago) }
    let_it_be(:upload4) { create(:import_export_upload, updated_at: 2.days.ago) }

    describe '.with_export_file' do
      it 'returns uploads with export file' do
        expect(described_class.with_export_file).to contain_exactly(upload1, upload3)
      end
    end

    describe '.updated_before' do
      it 'returns uploads for a specified date' do
        expect(described_class.updated_before(24.hours.ago)).to contain_exactly(upload3, upload4)
      end
    end
  end

  context 'ActiveRecord callbacks' do
    let(:after_save_callbacks) { described_class._save_callbacks.select { |cb| cb.kind == :after } }
    let(:after_commit_callbacks) { described_class._commit_callbacks.select { |cb| cb.kind == :after } }

    def find_callback(callbacks, key)
      callbacks.find { |cb| cb.instance_variable_get(:@key) == key }
    end

    it 'export file is stored in after_commit callback' do
      expect(find_callback(after_commit_callbacks, :store_export_file!)).to be_present
      expect(find_callback(after_save_callbacks, :store_export_file!)).to be_nil
    end

    it 'import file is stored in after_save callback' do
      expect(find_callback(after_save_callbacks, :store_import_file!)).to be_present
      expect(find_callback(after_commit_callbacks, :store_import_file!)).to be_nil
    end
  end
end
