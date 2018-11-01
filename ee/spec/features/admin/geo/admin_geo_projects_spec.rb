# frozen_string_literal: true

require 'spec_helper'

describe 'admin Geo Projects', :js, :geo do
  let!(:geo_node) { create(:geo_node) }
  let!(:synced_registry) { create(:geo_project_registry, :synced, :repository_verified) }
  let!(:sync_pending_registry) { create(:geo_project_registry, :synced, :repository_dirty) }
  let!(:sync_failed_registry) { create(:geo_project_registry, :existing_repository_sync_failed) }
  let!(:never_synced_registry) { create(:geo_project_registry) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    sign_in(create(:admin))
  end

  describe 'visiting geo projects initial page' do
    let(:page_url) { admin_geo_projects_path }

    before do
      visit(page_url)
      wait_for_requests
    end

    it 'shows all projects in the registry' do
      page.within(find('#content-body', match: :first)) do
        expect(page).to have_content(synced_registry.project.full_name)
        expect(page).to have_content(sync_pending_registry.project.full_name)
        expect(page).to have_content(sync_failed_registry.project.full_name)
        expect(page).to have_content(never_synced_registry.project.full_name)
      end
    end

    describe 'searching for a geo project' do
      it 'filters out projects with the search term' do
        fill_in :name, with: synced_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end
    end
  end

  describe 'visiting specific tab in geo projects page' do
    let(:page_url) { admin_geo_projects_path }

    before do
      visit(page_url)
      wait_for_requests

      click_link_or_button('Pending')
      wait_for_requests
    end

    it 'shows tab specific projects' do
      page.within(find('#content-body', match: :first)) do
        expect(page).not_to have_content(synced_registry.project.full_name)
        expect(page).to have_content(sync_pending_registry.project.full_name)
        expect(page).not_to have_content(sync_failed_registry.project.full_name)
        expect(page).not_to have_content(never_synced_registry.project.full_name)
      end
    end

    describe 'searching for a geo project' do
      it 'finds the project with the same name' do
        fill_in :name, with: sync_pending_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end

      it 'filters out project that matches with search but shouldnt be in the tab' do
        fill_in :name, with: synced_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end
    end
  end
end
