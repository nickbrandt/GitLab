# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentHelper do
  describe '#render_deployment_status' do
    context 'when using a manual deployment' do
      it 'renders a span tag' do
        deploy = build(:deployment, deployable: nil, status: :success)
        html = helper.render_deployment_status(deploy)

        expect(html).to have_css('span.ci-status.ci-success')
      end
    end

    context 'when using a deployment from a build' do
      it 'renders a link tag' do
        deploy = build(:deployment, status: :success)
        html = helper.render_deployment_status(deploy)

        expect(html).to have_css('a.ci-status.ci-success')
      end
    end
  end

  describe '#environments_detail_data' do
    subject { helper.environments_detail_data(user, project, environment) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project, reload: true) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns the correct data' do
      expect(subject[:data]).to eq({
        auto_stop_at: nil,
        can_admin_environment: 'true',
        can_destroy_environment: 'true',
        can_read_environment: 'true',
        can_stop_environment: 'true',
        can_update_environment: 'true',
        environment_cancel_auto_stop_path: cancel_auto_stop_project_environment_path(project, environment),
        environment_delete_path: environment_delete_path(environment),
        environment_edit_path: edit_project_environment_path(project, environment),
        environment_metrics_path: environment_metrics_path(environment),
        environment_stop_path: stop_project_environment_path(project, environment),
        environment_terminal_path: terminal_project_environment_path(project, environment),
        environments_fetch_path: project_environments_path(project, format: :json),
        external_url: environment.external_url,
        has_terminals: 'false',
        id: environment.id,
        is_environment_available: 'true',
        name: environment.name
      })
    end
  end
end
