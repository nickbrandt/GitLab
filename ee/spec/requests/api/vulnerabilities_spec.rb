# frozen_string_literal: true

require 'spec_helper'

describe API::Vulnerabilities do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:project) { create(:project, :public, :with_vulnerabilities) }
  let_it_be(:user) { create(:user) }

  describe "GET /projects/:id/vulnerabilities" do
    let(:project_vulnerabilities_path) { "/projects/#{project.id}/vulnerabilities" }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'returns all vulnerabilities of a project' do
        get api(project_vulnerabilities_path, user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('vulnerability_list', dir: 'ee')
        expect(response.headers['X-Total']).to eq project.vulnerabilities.count.to_s
      end

      it 'paginates the vulnerabilities according to the pagination params' do
        get api("#{project_vulnerabilities_path}?page=2&per_page=1", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.map { |v| v['id'] }).to contain_exactly(project.vulnerabilities.drop(1).take(1).first.id)
      end
    end

    it_behaves_like 'forbids access to vulnerability-like endpoint in expected cases'

    context 'when "first-class vulnerabilities" feature is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it_behaves_like 'getting list of vulnerability findings'
    end
  end
end
