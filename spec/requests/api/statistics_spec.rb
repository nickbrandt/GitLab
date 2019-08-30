# frozen_string_literal: true

require 'spec_helper'

describe API::Statistics, 'Statistics' do
  let(:path) { "/application/statistics" }

  describe "GET /application/statistics" do
    context 'when no user' do
      it "returns authentication error" do
        get api(path, nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden error" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:admin) }

      it 'matches the response schema' do
        get api(path, admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('statistics')
      end

      it 'gives the right statistics' do
        projects = create_list(:project, 4, namespace: create(:namespace, owner: admin))
        issues = create_list(:issue, 2, project: projects.first, updated_by: admin)

        create_list(:snippet, 2, :public, author: admin)
        create_list(:note, 2, author: admin, project: projects.first, noteable: issues.first)
        create_list(:milestone, 3, project: projects.first)
        create(:key, user: admin)
        create(:merge_request, source_project: projects.first)

        get api(path, admin)

        expect(json_response['issues']).to eq('2')
        expect(json_response['merge_requests']).to eq('1')
        expect(json_response['notes']).to eq('2')
        expect(json_response['snippets']).to eq('2')
        expect(json_response['forks']).to eq('0')
        expect(json_response['ssh_keys']).to eq('1')
        expect(json_response['milestones']).to eq('3')
        expect(json_response['active_users']).to eq('1')
      end
    end
  end
end
