# frozen_string_literal: true

require 'spec_helper'

describe Projects::ImportExport::ExportService do
  describe '#execute' do
    set(:user) { create(:user) }
    set(:project) { create(:project) }
    let(:shared) { project.import_export_shared }
    let(:service) { described_class.new(project, user) }
    let!(:after_export_strategy) { Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy.new }

    it 'saves the design repo' do
      expect(Gitlab::ImportExport::DesignRepoSaver).to receive(:new).and_call_original

      service.execute
    end

    context 'when the `export_designs` feature is disabled' do
      before do
        stub_feature_flags(export_designs: false)
      end

      it 'does not save the design repo' do
        expect(Gitlab::ImportExport::DesignRepoSaver).not_to receive(:new)

        service.execute
      end
    end
  end
end
