# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:geo rake tasks', :geo do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/geo'
    stub_licensed_features(geo: true)
  end

  describe 'gitlab:geo:check_replication_verification_status' do
    let(:run_task) { run_rake_task('gitlab:geo:check_replication_verification_status') }
    let!(:current_node) { create(:geo_node) }
    let!(:geo_node_status) { build(:geo_node_status, :healthy, geo_node: current_node) }

    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      allow(GeoNodeStatus).to receive(:current_node_status).and_return(geo_node_status)
      allow(Gitlab.config.geo.registry_replication).to receive(:enabled).and_return(true)

      allow(Gitlab::Geo::GeoNodeStatusCheck).to receive(:replication_verification_complete?)
                                                  .and_return(complete)
    end

    context 'when replication is up-to-date' do
      let(:complete) { true }

      it 'prints a success message' do
        expect { run_task }.to output(/SUCCESS - Replication is up-to-date/).to_stdout
      end
    end

    context 'when replication is not up-to-date' do
      let(:complete) { false }

      it 'prints an error message' do
        expect { run_task }.to output(/ERROR - Replication is not up-to-date/).to_stdout
      end

      it 'exits with a 1' do
        expect { run_task }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end
end
