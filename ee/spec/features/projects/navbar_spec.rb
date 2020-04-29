# frozen_string_literal: true

require 'spec_helper'

describe 'Project navbar' do
  include NavbarStructureHelper

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    insert_after_sub_nav_item(
      _('Labels'),
      within: _('Issues'),
      new_sub_nav_item_name: _('Service Desk')
    )

    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when issues analytics is available' do
    before do
      stub_licensed_features(issues_analytics: true)

      insert_after_sub_nav_item(
        _('Code Review'),
        within: _('Analytics'),
        new_sub_nav_item_name: _('Issues')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when security dashboard is available' do
    before do
      stub_licensed_features(security_dashboard: true)

      insert_after_nav_item(
        _('CI / CD'),
        new_nav_item: {
          nav_item: _('Security & Compliance'),
          nav_sub_items: [
            _('Security Dashboard'),
            _('Vulnerability List'),
            _('Configuration')
          ]
        }
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when packages are available' do
    before do
      allow(Gitlab.config.packages).to receive(:enabled).and_return(true)
      stub_licensed_features(packages: true)

      insert_after_nav_item(
        _('Operations'),
        new_nav_item: {
          nav_item: _('Packages'),
          nav_sub_items: [
            _('List')
          ]
        }
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when requirements is available' do
    before do
      stub_licensed_features(requirements: true)
      stub_feature_flags(requirements_management: { enabled: true, thing: project })

      insert_after_nav_item(
        _('Merge Requests'),
        new_nav_item: {
          nav_item: _('Requirements'),
          nav_sub_items: [_('List')]
        }
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
