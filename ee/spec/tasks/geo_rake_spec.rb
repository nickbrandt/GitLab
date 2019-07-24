require 'rake_helper'

describe 'geo rake tasks', :geo do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'tasks/geo'
    stub_licensed_features(geo: true)
  end

  describe 'set_primary_node task' do
    before do
      stub_config_setting(url: 'https://example.com:1234/relative_part')
      stub_geo_setting(node_name: 'Region 1 node')
    end

    it 'creates a GeoNode' do
      expect(GeoNode.count).to eq(0)

      run_rake_task('geo:set_primary_node')

      expect(GeoNode.count).to eq(1)

      node = GeoNode.first

      expect(node.name).to eq('Region 1 node')
      expect(node.uri.scheme).to eq('https')
      expect(node.url).to eq('https://example.com:1234/relative_part/')
      expect(node.primary).to be_truthy
    end
  end

  describe 'set_secondary_as_primary task' do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(current_node)
    end

    it 'removes primary and sets secondary as primary' do
      run_rake_task('geo:set_secondary_as_primary')

      expect(current_node.primary?).to be_truthy
      expect(GeoNode.count).to eq(1)
    end
  end

  describe 'update_primary_node_url task' do
    let(:primary_node) { create(:geo_node, :primary, url: 'https://secondary.geo.example.com') }

    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
      stub_current_geo_node(primary_node)
    end

    it 'updates Geo primary node URL' do
      run_rake_task('geo:update_primary_node_url')

      expect(primary_node.reload.url).to eq 'https://primary.geo.example.com/'
    end
  end

  describe 'status task', :geo_fdw do
    context 'without a valid license' do
      before do
        stub_licensed_features(geo: false)
      end

      it 'runs with an error' do
        expect { run_rake_task('geo:status') }.to raise_error("GitLab Geo is not supported with this license. Please contact the sales team: https://about.gitlab.com/sales.")
      end
    end

    context 'with a valid license' do
      let!(:current_node) { create(:geo_node) }
      let!(:primary_node) { create(:geo_node, :primary) }
      let!(:geo_event_log) { create(:geo_event_log) }
      let!(:geo_node_status) { build(:geo_node_status, :healthy, geo_node: current_node) }

      before do
        stub_licensed_features(geo: true)
        stub_current_geo_node(current_node)

        allow(GeoNodeStatus).to receive(:current_node_status).once.and_return(geo_node_status)
      end

      it 'runs with no error' do
        expect { run_rake_task('geo:status') }.not_to raise_error
      end

      context 'with a healthy node' do
        before do
          geo_node_status.status_message = nil
        end

        it 'shows status as healthy' do
          expect { run_rake_task('geo:status') }.to output(/Health Status: Healthy/).to_stdout
        end

        it 'does not show health status summary' do
          expect { run_rake_task('geo:status') }.not_to output(/Health Status Summary/).to_stdout
        end
      end

      context 'with an unhealthy node' do
        before do
          geo_node_status.status_message = 'Something went wrong'
        end

        it 'shows status as unhealthy' do
          expect { run_rake_task('geo:status') }.to output(/Health Status: Unhealthy/).to_stdout
        end

        it 'shows health status summary' do
          expect { run_rake_task('geo:status') }.to output(/Health Status Summary: Something went wrong/).to_stdout
        end
      end
    end
  end
end
