# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue move to another project' do
  let(:user) { create(:user) }
  let(:old_project) { create(:project, :repository) }
  let(:text) { 'Some issue description' }

  let(:issue) do
    create(:issue, description: text, project: old_project, author: user)
  end

  before do
    sign_in(user)
  end

  context 'service desk issue moved to a project with service desk disabled', :js do
    let(:project_title) { 'service desk disabled project' }
    let(:warning_selector) { '.js-alert-moved-from-service-desk-warning' }
    let(:namespace) { create(:namespace) }
    let(:regular_project) { create(:project, title: project_title, service_desk_enabled: false) }
    let(:service_desk_project) { build(:project, :private, namespace: namespace, service_desk_enabled: true) }
    let(:service_desk_issue) { create(:issue, project: service_desk_project, author: ::User.support_bot) }

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

      regular_project.add_reporter(user)
      service_desk_project.add_reporter(user)

      visit issue_path(service_desk_issue)

      find('.js-move-issue').click
      wait_for_requests
      find('.js-move-issue-dropdown-item', text: project_title).click
      find('.js-move-issue-confirmation-button').click
    end

    it 'shows an alert after being moved' do
      expect(page).to have_content('This project does not have Service Desk enabled')
    end

    it 'does not show an alert after being dismissed' do
      find("#{warning_selector} .js-close").click

      expect(page).to have_no_selector(warning_selector)

      page.refresh

      expect(page).to have_no_selector(warning_selector)
    end
  end
end
