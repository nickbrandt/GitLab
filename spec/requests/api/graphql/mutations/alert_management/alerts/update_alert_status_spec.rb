# frozen_string_literal: true

require 'spec_helper'

describe 'Setting the status of an alert' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:alert) { create(:alert_management_alert, project: project) }
  let(:input) { { status: 'RESOLVED', ended_at: 1.day.ago.to_s } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: alert.iid.to_s
    }
    graphql_mutation(:update_alert_status, variables.merge(input),
                     <<~QL
                       clientMutationId
                       errors
                       alert {
                         iid
                         status
                         endedAt
                       }
                     QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:update_alert_status) }

  before do
    project.add_developer(user)
  end

  it 'updates the status of the alert' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['alert']).to eq(
      'iid' => alert.iid.to_s,
      'status' => input[:status],
      'endedAt' => alert.reload.ended_at.strftime('%Y-%m-%dT%H:%M:%SZ')
    )
  end
end
