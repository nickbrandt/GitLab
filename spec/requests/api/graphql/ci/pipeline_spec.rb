# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'destroyable' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project_owner) { project.owner }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            destroyable
          }
        }
      }
    )
  end

  let(:pipeline_graphql_data) { graphql_data.dig('project', 'pipeline', 'destroyable') }

  context 'when user does not have the permission' do
    before do
      project.add_developer(user)
      post_graphql(query, current_user: user)
    end

    it 'returns false' do
      allow(Ability).to receive(:allowed?).with(user, :destroy_pipline, pipeline).and_return(false)

      expect(pipeline_graphql_data).to be(false)
    end
  end

  context 'when user is owner and therefore has the permission' do
    before do
      post_graphql(query, current_user: project_owner)
    end

    it 'returns true' do
      allow(Ability).to receive(:allowed?).with(project_owner, :destroy_pipline, pipeline).and_return(true)

      expect(pipeline_graphql_data).to be(true)
    end
  end
end
