# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Replication Nav', :js, :geo do
  include ::EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    stub_licensed_features(geo: true)
    sign_in(admin)
    stub_secondary_node
  end

  shared_examples 'active sidebar link' do |link_name|
    before do
      visit path
      wait_for_requests
    end

    it 'has active class' do
      navigation_link = page.find("a[title=\"#{link_name}\"]").find(:xpath, '..')
      expect(navigation_link[:class]).to include('active')
    end
  end

  describe 'visit admin/geo/replication/projects' do
    it_behaves_like 'active sidebar link', 'Projects' do
      let(:path) { admin_geo_projects_path }
    end
  end

  describe 'visit admin/geo/replication/uploads' do
    it_behaves_like 'active sidebar link', 'Uploads' do
      let(:path) { admin_geo_uploads_path }
    end
  end

  describe 'visit admin/geo/replication/designs' do
    it_behaves_like 'active sidebar link', 'Designs' do
      let(:path) { admin_geo_designs_path }
    end
  end

  describe 'visit admin/geo/replication/package_files' do
    it_behaves_like 'active sidebar link', 'Package Files' do
      let(:path) { admin_geo_package_files_path }
    end

    context 'when geo_self_service_framework feature is disabled' do
      before do
        stub_feature_flags(geo_self_service_framework: false)

        visit admin_geo_projects_path
        wait_for_requests
      end

      it 'does not render navigational element' do
        expect(page).not_to have_selector("a[title=\"Package Files\"]")
      end
    end
  end
end
