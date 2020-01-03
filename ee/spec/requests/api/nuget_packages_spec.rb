# frozen_string_literal: true
require 'spec_helper'

describe API::NugetPackages do
  include WorkhorseHelpers
  include EE::PackagesManagerApiSpecHelpers

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

          where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
            'PUBLIC'  | :developer  | true  | true  | 'process nuget service index request'   | :success
            'PUBLIC'  | :guest      | true  | true  | 'process nuget service index request'   | :success
            'PUBLIC'  | :developer  | true  | false | 'process nuget service index request'   | :success
            'PUBLIC'  | :guest      | true  | false | 'process nuget service index request'   | :success
            'PUBLIC'  | :developer  | false | true  | 'process nuget service index request'   | :success
            'PUBLIC'  | :guest      | false | true  | 'process nuget service index request'   | :success
            'PUBLIC'  | :developer  | false | false | 'process nuget service index request'   | :success
            'PUBLIC'  | :guest      | false | false | 'process nuget service index request'   | :success
            'PUBLIC'  | :anonymous  | false | true  | 'process nuget service index request'   | :success
            'PRIVATE' | :developer  | true  | true  | 'process nuget service index request'   | :success
            'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'         | :forbidden
            'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'         | :not_found
            'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'         | :not_found
            'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'         | :unauthorized
          end

          with_them do
            let(:token) { user_token ? personal_access_token.token : 'wrong' }
            let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

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

        it_behaves_like 'rejects nuget access with unknown project id'

        it_behaves_like 'rejects nuget access with invalid project id'
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

  describe 'PUT /api/v4/projects/:id/packages/nuget/authorize' do
    let_it_be(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
    let_it_be(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
    let(:url) { "/projects/#{project.id}/packages/nuget/authorize" }
    let(:headers) { {} }

    subject { put api(url), headers: headers }

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

          where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
            'PUBLIC'  | :developer  | true  | true  | 'process nuget workhorse authorization' | :success
            'PUBLIC'  | :guest      | true  | true  | 'rejects nuget packages access'         | :forbidden
            'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PUBLIC'  | :developer  | false | true  | 'rejects nuget packages access'         | :forbidden
            'PUBLIC'  | :guest      | false | true  | 'rejects nuget packages access'         | :forbidden
            'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'         | :unauthorized
            'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'         | :unauthorized
            'PUBLIC'  | :anonymous  | false | true  | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :developer  | true  | true  | 'process nuget workhorse authorization' | :success
            'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'         | :forbidden
            'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'         | :not_found
            'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'         | :not_found
            'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'         | :unauthorized
            'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'         | :unauthorized
          end

          with_them do
            let(:token) { user_token ? personal_access_token.token : 'wrong' }
            let(:user_headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }
            let(:headers) { user_headers.merge(workhorse_header) }

            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
            end

            after do
              project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            end

            it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
          end
        end

        it_behaves_like 'rejects nuget access with unknown project id'

        it_behaves_like 'rejects nuget access with invalid project id'
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

  describe 'PUT /api/v4/projects/:id/packages/nuget' do
    let_it_be(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
    let_it_be(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
    let_it_be(:file_name) { 'package.nupkg' }
    let(:url) { "/projects/#{project.id}/packages/nuget" }
    let(:headers) { {} }
    let(:params) { { file: temp_file(file_name) } }

    subject do
      workhorse_finalize(
        api(url),
        method: :put,
        file_key: :file,
        params: params,
        headers: headers
      )
    end

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

          where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
            'PUBLIC'  | :developer  | true  | true  | 'process nuget upload'          | :created
            'PUBLIC'  | :guest      | true  | true  | 'rejects nuget packages access' | :forbidden
            'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
            'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
            'PUBLIC'  | :developer  | false | true  | 'rejects nuget packages access' | :forbidden
            'PUBLIC'  | :guest      | false | true  | 'rejects nuget packages access' | :forbidden
            'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
            'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
            'PUBLIC'  | :anonymous  | false | true  | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :developer  | true  | true  | 'process nuget upload'          | :created
            'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access' | :forbidden
            'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access' | :not_found
            'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access' | :not_found
            'PRIVATE' | :developer  | false | false | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :guest      | false | false | 'rejects nuget packages access' | :unauthorized
            'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access' | :unauthorized
          end

          with_them do
            let(:token) { user_token ? personal_access_token.token : 'wrong' }
            let(:user_headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }
            let(:headers) { user_headers.merge(workhorse_header) }

            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
            end

            after do
              project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            end

            it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
          end
        end

        it_behaves_like 'rejects nuget access with unknown project id'

        it_behaves_like 'rejects nuget access with invalid project id'
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
end
