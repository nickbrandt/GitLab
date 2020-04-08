# frozen_string_literal: true

require "spec_helper"

describe 'Dismissing a vulnerability' do
  include GraphqlHelpers

  subject { graphql_mutation_response(:dismiss_vulnerability) }

  let_it_be(:current_user) { create(:user) }
  let(:finding) { create(:vulnerabilities_occurrence) }
  let(:vulnerability) { create(:vulnerability, findings: [finding]) }

  let(:mutation) do
    graphql_mutation(
      :dismiss_vulnerability,
      id: GitlabSchema.id_from_object(vulnerability).to_s
    )
  end

  before do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  it "changes the vulnerability's state to dismissed" do
    expect(vulnerability.reload).to be_dismissed
  end

  it "creates a dismissal feedback for the vulnerability's finding" do
  end
end
