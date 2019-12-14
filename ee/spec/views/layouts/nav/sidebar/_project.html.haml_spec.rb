# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_project' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    allow(view).to receive(:current_ref).and_return('master')

    stub_licensed_features(tracing: true, packages: true)
  end

  describe 'issue boards' do
    it 'has boards tab' do
      allow(view).to receive(:can?).and_return(true)
      allow(License).to receive(:feature_available?).and_call_original

      render

      expect(rendered).to have_css('a[title="Boards"]')
    end
  end

  describe 'Operations main link' do
    let(:user) { create(:user) }

    before do
      stub_licensed_features(feature_flags: true)

      project.project_feature.update(builds_access_level: feature)

      project.team.add_developer(user)
      sign_in(user)
    end

    context 'when ci/cd is disabled' do
      let(:feature) { ProjectFeature::DISABLED }

      it 'links to feature flags page' do
        render

        expect(rendered).to have_link('Operations', href: project_feature_flags_path(project))
      end
    end

    context 'when ci/cd is enabled' do
      let(:feature) { ProjectFeature::ENABLED }

      it 'links to metrics page' do
        render

        expect(rendered).to have_link('Operations', href: metrics_project_environments_path(project))
      end
    end
  end

  describe 'Operations > Tracing' do
    it 'is not visible when no valid license' do
      allow(view).to receive(:can?).and_return(true)
      stub_licensed_features(tracing: false)

      render

      expect(rendered).not_to have_text 'Tracing'
    end

    it 'is not visible to unauthorized user' do
      render

      expect(rendered).not_to have_text 'Tracing'
    end

    it 'links to Tracing page' do
      allow(view).to receive(:can?).and_return(true)

      render

      expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
    end

    context 'without project.tracing_external_url' do
      before do
        allow(view).to receive(:can?).and_return(true)
      end

      it 'links to Tracing page' do
        render

        expect(rendered).to have_link('Tracing', href: project_tracing_path(project))
      end
    end
  end

  describe 'Operations > Pod logs' do
    before do
      allow(view).to receive(:can?).with(nil, :read_environment, project).and_return(can_read_environment)
      allow(view).to receive(:can?).with(nil, :read_pod_logs, project).and_return(can_read_pod_logs)
      render
    end

    describe 'when the user can read environments and logs' do
      let(:can_read_environment) { true }
      let(:can_read_pod_logs) { true }

      it 'link is visible ' do
        expect(rendered).to have_link('Pod logs', href: project_logs_path(project))
      end
    end

    describe 'when the user cannot read environment or logs' do
      let(:can_read_environment) { false }
      let(:can_read_pod_logs) { false }

      it 'link is not visible ' do
        expect(rendered).not_to have_link 'Pod logs'
      end
    end

    describe 'when the user can read environment but not logs' do
      let(:can_read_environment) { true }
      let(:can_read_pod_logs) { false }

      it 'link is not visible ' do
        expect(rendered).not_to have_link 'Pod logs'
      end
    end
  end

  describe 'Security and Compliance' do
    before do
      allow(view).to receive(:can?).with(nil, :read_dependencies, project).and_return(can_read_dependencies)
      allow(view).to receive(:can?).with(nil, :read_project_security_dashboard, project).and_return(can_read_dashboard)
      render
    end

    describe 'when the user has full permissions' do
      let(:can_read_dashboard) { true }
      let(:can_read_dependencies) { true }

      it 'top level navigation link is visible' do
        expect(rendered).to have_link('Security & Compliance', href: project_security_dashboard_path(project))
      end

      it 'security dashboard link is visible' do
        expect(rendered).to have_link('Security Dashboard', href: project_security_dashboard_path(project))
      end

      it 'security configuration link is visible' do
        expect(rendered).to have_link('Configuration', href: project_security_configuration_path(project))
      end

      it 'dependency list link is visible' do
        expect(rendered).to have_link('Dependency List', href: project_dependencies_path(project))
      end
    end

    describe 'when the user can view only security dashboard' do
      let(:can_read_dashboard) { true }
      let(:can_read_dependencies) { false }

      it 'top level navigation link is visible' do
        expect(rendered).to have_link('Security & Compliance', href: project_security_dashboard_path(project))
      end

      it 'security dashboard link is visible' do
        expect(rendered).to have_link('Security Dashboard', href: project_security_dashboard_path(project))
      end

      it 'security configuration link is visible' do
        expect(rendered).to have_link('Configuration', href: project_security_configuration_path(project))
      end

      it 'dependency list link is not visible' do
        expect(rendered).not_to have_link('Dependency List', href: project_dependencies_path(project))
      end
    end

    describe 'when the user can view only dependency list' do
      let(:can_read_dashboard) { false }
      let(:can_read_dependencies) { true }

      it 'top level navigation link is visible' do
        expect(rendered).to have_link('Security & Compliance', href: project_dependencies_path(project))
      end

      it 'security dashboard link is not visible' do
        expect(rendered).not_to have_link('Security Dashboard', href: project_security_dashboard_path(project))
      end

      it 'security configuration link is not visible' do
        expect(rendered).not_to have_link('Configuration', href: project_security_configuration_path(project))
      end

      it 'dependency list link is visible' do
        expect(rendered).to have_link('Dependency List', href: project_dependencies_path(project))
      end
    end

    describe 'when the user has no permissions' do
      let(:can_read_dependencies) { false }
      let(:can_read_dashboard) { false }

      it 'top level navigation link is visible' do
        expect(rendered).not_to have_link('Security & Compliance', href: project_security_dashboard_path(project))
      end

      it 'security dashboard link is not visible' do
        expect(rendered).not_to have_link('Security Dashboard', href: project_security_dashboard_path(project))
      end

      it 'security configuration link is not visible' do
        expect(rendered).not_to have_link('Configuration', href: project_security_configuration_path(project))
      end

      it 'dependency list link is not visible' do
        expect(rendered).not_to have_link('Dependency List', href: project_dependencies_path(project))
      end
    end
  end

  describe 'Packages' do
    let(:user) { create(:user) }

    before do
      project.team.add_developer(user)
      sign_in(user)
      stub_container_registry_config(enabled: true)
    end

    context 'when packages is enabled' do
      it 'packages link is visible' do
        render

        expect(rendered).to have_link('Packages', href: project_packages_path(project))
      end

      it 'packages list link is visible' do
        render

        expect(rendered).to have_link('List', href: project_packages_path(project))
      end

      it 'container registry link is visible' do
        render

        expect(rendered).to have_link('Container Registry', href: project_container_registry_index_path(project))
      end
    end

    context 'when packages are disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'packages list link is not visible' do
        render

        expect(rendered).not_to have_link('List', href: project_packages_path(project))
      end

      it 'top level packages link links to container registry' do
        render

        expect(rendered).to have_link('Packages', href: project_container_registry_index_path(project))
      end

      it 'packages top level and container registry links are visible' do
        render

        expect(rendered).to have_link('Packages', href: project_container_registry_index_path(project))
        expect(rendered).to have_link('Container Registry', href: project_container_registry_index_path(project))
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it 'packages top level and list link are visible' do
        render

        expect(rendered).to have_link('Packages', href: project_packages_path(project))
        expect(rendered).to have_link('List', href: project_packages_path(project))
      end

      it 'container registry link is not visible' do
        render

        expect(rendered).not_to have_link('Container Registry', href: project_container_registry_index_path(project))
      end
    end

    context 'when both packages and container registry are disabled' do
      before do
        stub_licensed_features(packages: false)
        stub_container_registry_config(enabled: false)
      end

      it 'packages top level item is not visible' do
        render

        expect(rendered).not_to have_link('Packages', href: project_packages_path(project))
      end
    end
  end

  describe 'Settings > Operations' do
    it 'is not visible when no valid license' do
      allow(view).to receive(:can?).and_return(true)
      stub_licensed_features(tracing: false)

      render

      expect(rendered).not_to have_link project_settings_operations_path(project)
    end

    it 'is not visible to unauthorized user' do
      render

      expect(rendered).not_to have_link project_settings_operations_path(project)
    end

    it 'links to settings page' do
      allow(view).to receive(:can?).and_return(true)

      render

      expect(rendered).to have_link('Operations', href: project_settings_operations_path(project))
    end
  end
end
