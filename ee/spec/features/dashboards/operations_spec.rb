# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard operations', :js do
  it 'displays information about the last pipeline to an authenticated developer on the project' do
    stub_licensed_features(operations_dashboard: true)
    user = create(:user)
    project = create(:project, :repository, name: 'Great Project')
    pipeline = create(:ci_pipeline, project: project, sha: project.commit.sha, status: :running)
    project.add_developer(user)
    user.update(ops_dashboard_projects: [project])
    sign_in(user)

    visit operations_path

    expect(page).to have_text(project.name)
    expect(page).to have_text(pipeline.ref)
    expect(page).to have_text(pipeline.short_sha)
    expect(page).to have_text('Alerts')
    expect(page).to have_text(pipeline.status)
  end
end
