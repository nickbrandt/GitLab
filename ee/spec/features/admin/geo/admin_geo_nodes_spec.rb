require 'spec_helper'

describe 'admin Geo Nodes', :js do
  let!(:geo_node) { create(:geo_node) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    sign_in(create(:admin))
  end

  describe 'index' do
    it 'show all public Geo Nodes and create new node link' do
      visit admin_geo_nodes_path
      wait_for_requests

      expect(page).to have_link('New node', href: new_admin_geo_node_path)
      page.within(find('.geo-node-item', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end

    context 'hashed storage warnings' do
      let(:enable_warning) { 'Please enable and migrate to hashed storage' }
      let(:migrate_warning) { 'Please migrate all existing projects' }
      let(:user_callout_close_button) { '.user-callout .js-close' }

      context 'without hashed storage enabled' do
        before do
          stub_application_setting(hashed_storage_enabled: false)
        end

        it 'shows a dismissable warning to enable hashed storage' do
          visit admin_geo_nodes_path

          expect(page).to have_content enable_warning
          expect(page).to have_selector user_callout_close_button
        end
      end

      context 'with hashed storage enabled' do
        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        context 'with all projects in hashed storage' do
          let!(:project) { create(:project) }

          it 'does not show any hashed storage warning' do
            visit admin_geo_nodes_path

            expect(page).not_to have_content enable_warning
            expect(page).not_to have_content migrate_warning
            expect(page).not_to have_selector user_callout_close_button
          end
        end

        context 'with at least one project in legacy storage' do
          let!(:project) { create(:project, :legacy_storage) }

          it 'shows a dismissable warning to migrate to hashed storage' do
            visit admin_geo_nodes_path

            expect(page).to have_content migrate_warning
            expect(page).to have_selector user_callout_close_button
          end
        end
      end
    end
  end

  describe 'create a new Geo Nodes' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit new_admin_geo_node_path
    end

    it 'creates a new Geo Node' do
      check 'This is a primary node'
      fill_in 'geo_node_url', with: 'https://test.gitlab.com'
      click_button 'Add Node'

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests

      page.within(find('.geo-node-item', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end

    it 'changes re-verification interval field visibility based on primary node checkbox' do
      expect(page).not_to have_field('Re-verification interval')

      check 'This is a primary node'

      expect(page).to have_field('Re-verification interval')

      uncheck 'This is a primary node'

      expect(page).not_to have_field('Re-verification interval')
    end

    it 'returns an error message when a duplicate primary is added' do
      create(:geo_node, :primary)

      check 'This is a primary node'
      fill_in 'geo_node_url', with: 'https://another-primary.example.com'
      click_button 'Add Node'

      expect(current_path).to eq admin_geo_nodes_path

      expect(page).to have_content('Primary node already exists')
    end
  end

  describe 'update an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
      page.within(find('.geo-node-actions', match: :first)) do
        page.click_link('Edit')
      end
    end

    it 'updates an existing Geo Node' do
      fill_in 'URL', with: 'http://newsite.com'
      check 'This is a primary node'
      click_button 'Save changes'

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests

      page.within(find('.geo-node-item', match: :first)) do
        expect(page).to have_content('http://newsite.com')
        expect(page).to have_content('Primary')
      end
    end
  end

  describe 'remove an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'removes an existing Geo Node' do
      page.within(find('.geo-node-actions', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove')
      end

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests
      expect(page).not_to have_css('.geo-node-item')
    end
  end
end
