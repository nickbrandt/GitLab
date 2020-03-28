# frozen_string_literal: true

require 'spec_helper'

describe 'admin Geo Sidebar', :js, :geo do
  include ::EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    stub_licensed_features(geo: true)
    sign_in(admin)
  end

  shared_examples 'active sidebar link' do |link_name|
    before do
      visit path
      wait_for_requests
    end

    it 'has active class' do
      sidebar_link = page.find("a[title=\"#{link_name}\"]").find(:xpath, '..')
      expect(sidebar_link[:class]).to include('active')
    end
  end

  describe 'clicking the nodes link' do
    it_behaves_like 'active sidebar link', 'Nodes' do
      let(:path) { admin_geo_nodes_path }
    end
  end

  describe 'clicking the settings link' do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    end

    it_behaves_like 'active sidebar link', 'Settings' do
      let(:path) { admin_geo_settings_path }
    end
  end

  context 'on secondary' do
    before do
      stub_secondary_node
    end

    describe 'clicking the projects link' do
      it_behaves_like 'active sidebar link', 'Projects' do
        let(:path) { admin_geo_projects_path }
      end
    end

    describe 'clicking the designs link' do
      it_behaves_like 'active sidebar link', 'Designs' do
        let(:path) { admin_geo_designs_path }
      end
    end

    describe 'clicking the uploads link' do
      it_behaves_like 'active sidebar link', 'Uploads' do
        let(:path) { admin_geo_uploads_path }
      end
    end
  end
end
