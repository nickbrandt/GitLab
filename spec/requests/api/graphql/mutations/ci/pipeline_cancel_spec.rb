# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineCancel' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, :running, project: project, user: user) }

  let(:mutation) do
    graphql_mutation(:pipeline_cancel, {},
      <<-QL
        errors
      QL
    )
  end

  before do
    project.add_maintainer(user)
  end

  it 'does not change any pipelines not owned by the current user' do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(build).not_to be_canceled
  end

  it "cancels all of the current user's cancelable pipelines" do
    build = create(:ci_build, :running, pipeline: pipeline)

    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(build.reload).to be_canceled
  end
end
