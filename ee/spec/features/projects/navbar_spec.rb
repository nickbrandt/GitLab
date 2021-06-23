# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar' do
  include NavbarStructureHelper

  include_context 'project navbar structure'

  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }

  before do
    sign_in(user)

    insert_package_nav(_('Infrastructure'))
    insert_infrastructure_registry_nav
  end

  context 'when issue analytics is available' do
    before do
      stub_licensed_features(issues_analytics: true)

      insert_after_sub_nav_item(
        _('Code Review'),
        within: _('Analytics'),
        new_sub_nav_item_name: _('Issue')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when security dashboard is available' do
    let(:security_and_compliance_nav_item) do
      {
        nav_item: _('Security & Compliance'),
        nav_sub_items: [
          _('Security Dashboard'),
          _('Vulnerability Report'),
          s_('OnDemandScans|On-demand Scans'),
          _('Audit Events'),
          _('Configuration')
        ]
      }
    end

    before do
      stub_licensed_features(security_dashboard: true, security_on_demand_scans: true)

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when packages are available' do
    before do
      stub_config(packages: { enabled: true }, registry: { enabled: false })
    end

    context 'when container registry is available' do
      before do
        stub_config(registry: { enabled: true })

        insert_container_nav

        insert_after_sub_nav_item(
          _('Monitor'),
          within: _('Settings'),
          new_sub_nav_item_name: _('Packages & Registries')
        )

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end
  end

  context 'when requirements is available' do
    before do
      stub_licensed_features(requirements: true)
      insert_after_nav_item(
        _('Merge requests'),
        new_nav_item: {
          nav_item: _('Requirements'),
          nav_sub_items: []
        }
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
