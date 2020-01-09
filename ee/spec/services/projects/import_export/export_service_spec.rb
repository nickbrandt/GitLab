# frozen_string_literal: true

require 'spec_helper'

describe Projects::ImportExport::ExportService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let(:shared) { project.import_export_shared }
    let(:service) { described_class.new(project, user) }
    let!(:after_export_strategy) { Gitlab::ImportExport::AfterExportStrategies::DownloadNotificationStrategy.new }

    it 'saves the design repo' do
      expect(Gitlab::ImportExport::DesignRepoSaver).to receive(:new).and_call_original

      service.execute
    end
  end
end
