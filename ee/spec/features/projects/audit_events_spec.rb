# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Audit Events', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:pete) { create(:user, name: 'Pete') }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(audit_events: false)
    end

    it 'returns 404' do
      reqs = inspect_requests do
        visit project_audit_events_path(project)
      end

      expect(reqs.first.status_code).to eq(404)
    end

    it 'does not have Audit Events button in head nav bar' do
      visit edit_project_path(project)

      expect(page).not_to have_link('Audit Events')
    end
  end

  context 'unlicensed but we show promotions' do
    before do
      stub_licensed_features(audit_events: false)
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)
      allow(LicenseHelper).to receive(:show_promotions?).and_return(true)
    end

    include_context '"Security & Compliance" permissions' do
      let(:response) { inspect_requests { visit project_audit_events_path(project) }.first }
    end

    it 'returns 200' do
      reqs = inspect_requests do
        visit project_audit_events_path(project)
      end

      expect(reqs.first.status_code).to eq(200)
    end

    it 'has Audit Events button in head nav bar' do
      visit project_audit_events_path(project)

      expect(page).to have_link('Audit Events')
    end

    it 'does not have Project audit events in the header' do
      visit project_audit_events_path(project)

      expect(page).not_to have_content('Project audit events')
    end
  end

  it 'has Audit Events button in head nav bar' do
    visit project_audit_events_path(project)

    expect(page).to have_link('Audit Events')
  end

  it 'has Project audit events in the header' do
    visit project_audit_events_path(project)

    expect(page).to have_content('Project audit events')
  end

  describe 'adding an SSH key' do
    it "appears in the project's audit events" do
      stub_licensed_features(audit_events: true)

      visit new_project_deploy_key_path(project)

      fill_in 'deploy_key_title', with: 'laptop'
      fill_in 'deploy_key_key', with: 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop'

      click_button 'Add key'

      visit project_audit_events_path(project)

      expect(page).to have_content('Added deploy key')

      visit project_deploy_keys_path(project)

      click_button 'Remove'
      click_button 'Remove deploy key'

      visit project_audit_events_path(project)

      wait_for('Audit event background creation job is done', polling_interval: 0.5, reload: true) do
        page.has_content?('Removed deploy key', wait: 0)
      end
    end
  end

  describe 'changing a user access level' do
    before do
      project.add_developer(pete)
    end

    it "appears in the project's audit events" do
      visit project_project_members_path(project)

      page.within find_member_row(pete) do
        click_button 'Developer'
        click_button 'Maintainer'
      end

      page.within('.qa-project-sidebar') do
        find(:link, text: 'Security & Compliance').click
        click_link 'Audit Events'
      end

      page.within('.audit-log-table') do
        expect(page).to have_content 'Changed access level from Developer to Maintainer'
        expect(page).to have_content(project.owner.name)
        expect(page).to have_content('Pete')
      end
    end
  end

  describe 'changing merge request approval permission for authors and reviewers' do
    before do
      project.add_developer(pete)
    end

    it "appears in the project's audit events" do
      visit edit_project_path(project)

      page.within('#js-merge-request-approval-settings') do
        uncheck 'project_merge_requests_author_approval'
        check 'project_merge_requests_disable_committers_approval'
        click_button 'Save changes'
      end

      wait_for_all_requests

      page.within('.qa-project-sidebar') do
        click_link 'Security & Compliance'
        click_link 'Audit Events'
      end

      wait_for_all_requests

      page.within('.audit-log-table') do
        expect(page).to have_content(project.owner.name)
        expect(page).to have_content('Changed prevent merge request approval from authors')
        expect(page).to have_content('Changed prevent merge request approval from reviewers')
        expect(page).to have_content(project.name)
      end
    end
  end

  describe 'filter by date' do
    let!(:audit_event_1) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: 5.days.ago) }
    let!(:audit_event_2) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: 3.days.ago) }
    let!(:audit_event_3) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: Date.current) }
    let!(:events_path) { :project_audit_events_path }
    let!(:entity) { project }

    it_behaves_like 'audit events date filter'
  end

  describe 'combined list of authenticated and unauthenticated users' do
    let!(:audit_event_1) { create(:project_audit_event, :unauthenticated, entity_type: 'Project', entity_id: project.id) }
    let!(:audit_event_2) { create(:project_audit_event, author_id: non_existing_record_id, entity_type: 'Project', entity_id: project.id) }
    let!(:audit_event_3) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id) }

    it 'displays the correct authors names' do
      visit project_audit_events_path(project)

      wait_for_all_requests

      page.within('.audit-log-table') do
        expect(page).to have_content('An unauthenticated user')
        expect(page).to have_content("#{audit_event_2.author_name} (removed)")
        expect(page).to have_content(audit_event_3.user.name)
      end
    end
  end
end
