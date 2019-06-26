# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  include ApiHelpers

  describe 'GET index.json' do
    context 'when security dashboard feature is disabled' do
      it 'returns 404' do
        user = create(:user)
        project = create(:project)
        project.add_maintainer(user)

        sign_in(user)
        stub_licensed_features(security_dashboard: false)

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

    # context 'when security dashboard feature is enabled' do
    #   context 'when user has guest access' do
    #     it 'returns 403' do
    #   context 'when user has developer access' do
    #     context 'when no page request' do
    #       it "returns a list of vulnerabilities" do
    #     context 'when page requested' do
    #       it "returns a list of vulnerabilities" do
    #     context 'with vulnerability feedback' do
    #       it "avoids N+1 queries", :with_request_store do
    #     context 'with multiple report types' do
    #       it "returns a list of vulnerabilities for all report types without filter" do
    #       it "returns a list of vulnerabilities for sast only if filter is enabled" do
    #       it "returns a list of vulnerabilities of all types with multi filter" do

  # describe 'GET summary.json' do
    # context 'when security dashboard feature is disabled' do
    #   it 'returns 404' do
    # context 'when security dashboard feature is enabled' do
    #   context 'when user has guest access' do
    #     it 'returns 403' do
    #   context 'when user has developer access' do
    #     it 'returns vulnerabilities counts for all report types' do
    #     context 'with enabled filters' do
    #       it 'returns counts for filtered vulnerabilities' do

  # describe 'GET history.json' do
    # context 'when security dashboard feature is disabled' do
    #   it 'returns 404' do
    # context 'when security dashboard feature is enabled' do
    #   context 'when user has guest access' do
    #     it 'returns 403' do
    #   context 'when user has developer access' do
    #     it 'returns vulnerability history within last 90 days' do
    #     it 'returns empty history if there are no vulnerabilities within last 90 days' do
    #     it 'returns filtered history if filters are enabled' do
  # end
end
