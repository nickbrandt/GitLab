# frozen_string_literal: true
require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', :js do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, approvals_before_merge: 1) }
  let(:group) { create(:group) }
  let(:group_member) { create(:user) }
  let(:non_member) { create(:user) }

  before do
    stub_feature_flags(approval_rules: false)

    sign_in(user)
    project.add_maintainer(user)
    group.add_developer(user)
    group.add_developer(group_member)
  end

  it 'adds approver' do
    visit edit_project_path(project)

    find('#s2id_approver_user_and_group_ids .select2-input').click

    wait_for_requests

    expect(find('.select2-results')).to have_content(user.name)
    find('.user-result', text: user.name).click
    click_button 'Add'

    expect(find('.js-current-approvers')).to have_content(user.name)

    find('.js-select-user-and-group').click

    expect(find('.select2-results')).not_to have_content(user.name)
  end

  it 'filter approvers' do
    visit edit_project_path(project)
    find('.js-select-user-and-group').click

    expect(find('.select2-results')).to have_content(user.name)
    expect(find('.select2-results')).not_to have_content(non_member.name)
  end

  it 'adds approver group' do
    visit edit_project_path(project)

    find('#s2id_approver_user_and_group_ids .select2-input').click

    wait_for_requests

    within('.js-current-approvers') do
      expect(find('.card-header .badge')).to have_content('0')
    end

    expect(find('.select2-results')).to have_content(group.name)
    find('.select2-results .group-result').click
    click_button 'Add'

    expect(find('.approver-list-loader')).to be_visible
    expect(page).to have_css('.js-current-approvers li.approver-group', count: 1)

    expect(page).to have_css('.js-current-approvers li.approver-group', count: 1)
    within('.js-current-approvers') do
      expect(find('.card-header .badge')).to have_content('2')
    end
  end

  context 'with an approver group' do
    before do
      create(:approver_group, group: group, target: project)
    end

    it 'removes approver group' do
      visit edit_project_path(project)

      expect(find('.js-current-approvers')).to have_content(group.name)

      within('.js-current-approvers') do
        accept_confirm { click_on "Remove" }
      end

      expect(find('.js-current-approvers')).not_to have_content(group.name)
    end
  end

  context 'issuable default templates feature not available' do
    before do
      stub_licensed_features(issuable_default_templates: false)
    end

    it 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_merge_requests_template')
    end
  end

  context 'issuable default templates feature is available' do
    before do
      stub_licensed_features(issuable_default_templates: true)
    end

    it 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).to have_selector('#project_merge_requests_template')
    end
  end

  shared_examples 'the merge train feature is not available' do
    it 'does not render the merge trains checkbox' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_merge_trains_enabled')
    end
  end

  context 'when merge_pipelines and merge_trains are disabled' do
    before do
      stub_licensed_features(merge_pipelines: false, merge_trains: false)
    end

    it_behaves_like 'the merge train feature is not available'
  end

  context 'when merge_pipelines is disabled and merge_trains is enabled' do
    before do
      stub_licensed_features(merge_pipelines: false, merge_trains: true)
    end

    it_behaves_like 'the merge train feature is not available'
  end

  context 'when merge_trains is disabled and merge_pipelines is enabled' do
    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: false)
    end

    it_behaves_like 'the merge train feature is not available'
  end

  context 'when merge_pipelines and merge_trains are enabled' do
    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
    end

    context 'when both the merge pipelines and merge trains checkboxes are unchecked' do
      before do
        visit edit_project_path(project)
      end

      it 'automatically checks the merge pipelines checkbox when the merge trains checkbox is checked' do
        expect(page.find('#project_merge_trains_enabled').checked?).to be false

        expect(page.find('#project_merge_pipelines_enabled').checked?).to be false

        check('project_merge_trains_enabled')

        expect(page.find('#project_merge_trains_enabled').checked?).to be true

        expect(page.find('#project_merge_pipelines_enabled').checked?).to be true
      end
    end

    context 'when both the merge pipelines and merge trains checkboxes are checked' do
      before do
        project.update(merge_pipelines_enabled: true, merge_trains_enabled: true)
        visit edit_project_path(project)
      end

      it 'automatically unchecks the merge trains checkbox when the merge pipelines checkbox is unchecked' do
        expect(page.find('#project_merge_trains_enabled').checked?).to be true

        expect(page.find('#project_merge_pipelines_enabled').checked?).to be true

        uncheck('project_merge_pipelines_enabled')

        expect(page.find('#project_merge_trains_enabled').checked?).to be false

        expect(page.find('#project_merge_pipelines_enabled').checked?).to be false
      end
    end
  end
end
