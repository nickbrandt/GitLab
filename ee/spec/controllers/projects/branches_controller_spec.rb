# frozen_string_literal: true

require 'spec_helper'

describe Projects::BranchesController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    allow(project).to receive(:branches).and_return(['master'])
    controller.instance_variable_set(:@project, project)

    sign_in(user)
  end

  describe 'GET #index' do
    let(:import_state) { create(:import_state, next_execution_timestamp: Time.now, last_update_at: Time.now, last_successful_update_at: Time.now) }

    render_views

    before do
      project.update!(mirror: true, import_state: import_state, import_url: 'https://import.url', mirror_user: user)
      allow(project.repository).to receive(:diverged_from_upstream?) { true }
    end

    it 'renders the diverged from upstream partial' do
      get :index,
          format: :html,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            state: 'all'
          }

      expect(controller).to render_template('projects/branches/_diverged_from_upstream')
      expect(response.body).to match(/diverged from upstream/)
    end
  end
end
