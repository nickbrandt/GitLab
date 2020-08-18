# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineDestroy' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, :success, project: project, user: user) }

  let(:mutation) do
    variables = {
      id: pipeline.id
    }
    graphql_mutation(:pipeline_destroy, variables,
                     <<-QL
                       errors
                     QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:pipeline_destroy) }

  before do
    project.add_maintainer(user)
  end

  it 'returns an error if the user is not allowed to destroy the pipeline' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).not_to be_empty
  end

  it 'retries a pipeline' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
  end
end
