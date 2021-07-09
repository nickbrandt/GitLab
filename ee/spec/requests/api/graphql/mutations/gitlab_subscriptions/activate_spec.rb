# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Activate a subscription' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:license_key) { build(:gitlab_license).export }

  let(:activation_code) { 'activation_code' }
  let(:mutation) do
    graphql_mutation(:gitlab_subscription_activate, { activation_code: activation_code })
  end

  let!(:application_setting) do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    create(:application_setting)
  end

  let(:remote_response) do
    {
      success: true,
      data: {
        "data" => {
          "cloudActivationActivate" => {
            "licenseKey" => license_key,
            "errors" => []
          }
        }
      }
    }
  end

  it 'persists license key' do
    expect(Gitlab::SubscriptionPortal::Client)
      .to receive(:execute_graphql_query)
      .with({
        query: an_instance_of(String),
        variables: {
          activationCode: activation_code,
          instanceIdentifier: application_setting.uuid
        }
      })
      .and_return(remote_response)

    post_graphql_mutation(mutation, current_user: current_user)

    mutation_response = graphql_mutation_response(:gitlab_subscription_activate)
    created_license = License.last

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['license']).to eq(
      {
        'id' => "gid://gitlab/License/#{created_license.id}",
        'type' => License::LICENSE_FILE_TYPE,
        'plan' => created_license.plan,
        'name' => created_license.licensee_name,
        'email' => created_license.licensee_email,
        'company' => created_license.licensee_company,
        'startsAt' => created_license.starts_at.to_s,
        'expiresAt' => created_license.expires_at.to_s,
        'blockChangesAt' => created_license.block_changes_at.to_s,
        'activatedAt' => created_license.created_at.to_date.to_s,
        'lastSync' => created_license.last_synced_at.iso8601,
        'usersInLicenseCount' => nil,
        'billableUsersCount' => 1,
        'maximumUserCount' => 1,
        'usersOverLicenseCount' => 0
      }
    )
    expect(created_license.data).to eq(license_key)
  end
end
