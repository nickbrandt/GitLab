# frozen_string_literal: true
require 'spec_helper'

describe API::NugetPackages do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  describe 'GET /api/v4/projects/:id/packages/nuget' do
    let(:url) { "/projects/#{project.id}/packages/nuget/index.json" }

    subject { get api(url) }

    context 'with packages features enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with feature flag enabled' do
        before do
          stub_feature_flags(nuget_package_registry: { enabled: true, thing: project })
        end

        context 'with valid project' do
          using RSpec::Parameterized::TableSyntax

          where(:project_visibility_level, :user_role, :member, :wrong_token, :shared_examples_name, :expected_status) do
            'PUBLIC'  | :developer  | true  | false | 'returns nuget service index'   | :success
            'PUBLIC'  | :guest      | true  | false | 'returns nuget service index'   | :success
            'PUBLIC'  | :developer  | true  | true  | 'returns nuget service index'   | :success
            'PUBLIC'  | :guest      | true  | true  | 'returns nuget service index'   | :success
            'PUBLIC'  | :developer  | false | false | 'returns nuget service index'   | :success
            'PUBLIC'  | :guest      | false | false | 'returns nuget service index'   | :success
            'PUBLIC'  | :developer  | false | true  | 'returns nuget service index'   | :success
            'PUBLIC'  | :guest      | false | true  | 'returns nuget service index'   | :success
            'PUBLIC'  | :anonymous  | false | false | 'returns nuget service index'   | :success
            'PRIVATE' | :developer  | true  | false | 'returns nuget service index'   | :success
            'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access' | :forbidden
            'PRIVATE' | :developer  | true  | true  | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :developer  | false | false | 'rejects nuget packages access' | :not_found
            'PRIVATE' | :guest      | false | false | 'rejects nuget packages access' | :not_found
            'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :anonymous  | false | false | 'rejects nuget packages access' | :unauthorized
          end

          with_them do
            let(:token) { wrong_token ? 'wrong' : personal_access_token.token }
            let(:headers) { user_role == :anonymous ? {} : build_auth_headers(basic_http_auth(user.username, token)) }

            subject { get api(url), headers: headers }

            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
            end

            after do
              project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            end

            it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
          end
        end

        context 'with an unknown project' do
          let(:project) { OpenStruct.new(id: 1234567890) }

          context 'as anonymous' do
            it_behaves_like 'rejects nuget packages access', :anonymous, :unauthorized
          end

          context 'as authenticated user' do
            subject { get api(url), headers: build_auth_headers(basic_http_auth(user.username, personal_access_token.token)) }

            it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
          end
        end

        context 'with a project id with invalid integers' do
          using RSpec::Parameterized::TableSyntax

          let(:project) { OpenStruct.new(id: id) }

          where(:id, :status) do
            '/../'       | :unauthorized
            ''           | :not_found
            '%20'        | :unauthorized
            '%2e%2e%2f'  | :unauthorized
            'NaN'        | :unauthorized
            00002345     | :unauthorized
            'anything25' | :unauthorized
          end

          with_them do
            it_behaves_like 'rejects nuget packages access', :anonymous, params[:status]
          end
        end

        context 'with invalid format' do
          let(:url) { "/projects/#{project.id}/packages/nuget/index.xls" }

          it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
        end
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(nuget_package_registry: { enabled: false, thing: project })
        end

        it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
      end
    end

    context 'with packages features disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it_behaves_like 'rejects nuget packages access', :anonymous, :forbidden
    end
  end

  def build_auth_headers(value)
    { 'HTTP_AUTHORIZATION' => value }
  end

  def basic_http_auth(username, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
