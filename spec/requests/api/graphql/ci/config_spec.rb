# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciConfig' do
  include GraphqlHelpers

  subject(:post_graphql_query) { post_graphql(query, current_user: user) }

  let(:user) { create(:user) }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:query) do
    %(
      query {
        ciConfig(content: "#{content}") {
          status
          errors
          stages {
            nodes {
              name
              groups {
                nodes {
                  name
                  size
                  jobs {
                    nodes {
                      name
                      groupName
                      stage
                      needs {
                        nodes {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    )
  end

  before do
    post_graphql_query
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct structure' do
    response_stages = graphql_data['ciConfig']['stages']['nodes']
    response_groups = response_stages.map { |stage| stage['groups']['nodes'] }.flatten
    response_jobs = response_groups.first['jobs']['nodes']
    response_needs = response_groups.last['jobs']['nodes'].first['needs']['nodes']

    expect(graphql_data['ciConfig']['status']).to eq('VALID')

    expect(response_stages).to include(
      hash_including('name' => 'build'), hash_including('name' => 'test')
    )
    expect(response_groups).to include(
      hash_including('name' => 'rspec', 'size' => 2),
      hash_including('name' => 'spinach', 'size' => 1),
      hash_including('name' => 'docker', 'size' => 1)
    )

    expect(response_jobs).to include(
      hash_including('groupName' => 'rspec', 'name' => 'rspec 0 1', 'needs' => { 'nodes' => [] }, 'stage' => 'build'),
      hash_including('groupName' => 'rspec', 'name' => 'rspec 0 2', 'needs' => { 'nodes' => [] }, 'stage' => 'build')
    )
    expect(response_needs).to include(
      hash_including('name' => 'rspec 0 1'), hash_including('name' => 'spinach')
    )
  end
end
