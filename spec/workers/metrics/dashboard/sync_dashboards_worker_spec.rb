# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::SyncDashboardsWorker do
  subject(:worker) { described_class.new }

  let(:project) { create(:project) }
  let(:dashboard_paths) { [".gitlab/dashboards/dashboard1.yml", ".gitlab/dashboards/dashboard2.yml"] }

  describe ".perform" do
    before do
      expect(::Gitlab::Metrics::Dashboard::RepoDashboardFinder).to receive(:list_dashboards).with(project)
        .and_return(dashboard_paths)
    end

    it 'calls importer for each dashboard path' do
      dashboard_paths.each do |dashboard_path|
        expect(::Gitlab::Metrics::Dashboard::Importer).to receive(:new)
          .with(dashboard_path, project).and_return(double('importer', execute!: true))
      end

      worker.perform(project.id)
    end
  end
end
