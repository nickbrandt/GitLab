# frozen_string_literal: true
require 'spec_helper'

describe API::ComposerPackages do
  include EE::PackagesManagerApiSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:project, reload: true) { create(:project, :repository, path: 'my.project') }

  describe 'GET /api/v4/group/:id/-/packages/composer/packages' do
    let(:url) { "/group/#{group.id}/-/packages/composer/packages.json" }

    subject { get api(url) }

    context 'with packages features enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :anonymous  | false | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :not_found
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

          subject { get api(url), headers: headers }

          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      it_behaves_like 'rejects Composer access with unknown group id'
    end

    it_behaves_like 'rejects Composer packages access with packages features disabled'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/p/:sha.json' do
    let(:sha) { '123' }
    let(:url) { "/group/#{group.id}/-/packages/composer/p/#{sha}.json" }

    subject { get api(url) }

    context 'with packages features enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :anonymous  | false | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :not_found
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

          subject { get api(url), headers: headers }

          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      it_behaves_like 'rejects Composer access with unknown group id'
    end

    it_behaves_like 'rejects Composer packages access with packages features disabled'
  end

  describe 'GET /api/v4/group/:id/-/packages/composer/*package_name.json' do
    let(:package_name) { 'foobar' }
    let(:url) { "/group/#{group.id}/-/packages/composer/#{package_name}.json" }

    subject { get api(url) }

    context 'with packages features enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | true  | 'process Composer api request' | :success
          'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :success
          'PUBLIC'  | :anonymous  | false | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :success
          'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :guest      | false | false | 'process Composer api request' | :not_found
          'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :not_found
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

          subject { get api(url), headers: headers }

          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      it_behaves_like 'rejects Composer access with unknown group id'
    end

    it_behaves_like 'rejects Composer packages access with packages features disabled'
  end

  describe 'POST /api/v4/projects/:id/packages/composer' do
    let(:url) { "/projects/#{project.id}/packages/composer" }
    let(:params) { {} }

    subject { post api(url), headers: headers, params: params }

    shared_examples 'composer package publish' do
      context 'with packages features enabled' do
        before do
          stub_licensed_features(packages: true)
        end

        context 'with valid project' do
          using RSpec::Parameterized::TableSyntax

          where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
            'PUBLIC'  | :developer  | true  | true  | 'process Composer api request' | :created
            'PUBLIC'  | :guest      | true  | true  | 'process Composer api request' | :forbidden
            'PUBLIC'  | :developer  | true  | false | 'process Composer api request' | :unauthorized
            'PUBLIC'  | :guest      | true  | false | 'process Composer api request' | :unauthorized
            'PUBLIC'  | :developer  | false | true  | 'process Composer api request' | :forbidden
            'PUBLIC'  | :guest      | false | true  | 'process Composer api request' | :forbidden
            'PUBLIC'  | :developer  | false | false | 'process Composer api request' | :unauthorized
            'PUBLIC'  | :guest      | false | false | 'process Composer api request' | :unauthorized
            'PUBLIC'  | :anonymous  | false | true  | 'process Composer api request' | :unauthorized
            'PRIVATE' | :developer  | true  | true  | 'process Composer api request' | :created
            'PRIVATE' | :guest      | true  | true  | 'process Composer api request' | :forbidden
            'PRIVATE' | :developer  | true  | false | 'process Composer api request' | :unauthorized
            'PRIVATE' | :guest      | true  | false | 'process Composer api request' | :unauthorized
            'PRIVATE' | :developer  | false | true  | 'process Composer api request' | :not_found
            'PRIVATE' | :guest      | false | true  | 'process Composer api request' | :not_found
            'PRIVATE' | :developer  | false | false | 'process Composer api request' | :unauthorized
            'PRIVATE' | :guest      | false | false | 'process Composer api request' | :unauthorized
            'PRIVATE' | :anonymous  | false | true  | 'process Composer api request' | :unauthorized
          end

          with_them do
            let(:token) { user_token ? personal_access_token.token : 'wrong' }
            let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
            end

            it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
          end
        end

        it_behaves_like 'rejects Composer access with unknown project id'
      end
    end

    it_behaves_like 'rejects Composer packages access with packages features disabled'

    context 'with no tag or branch params' do
      let(:headers) { build_basic_auth_header(user.username, personal_access_token.token) }

      before do
        stub_licensed_features(packages: true)
      end

      it_behaves_like 'process Composer api request', :developer, :bad_request
    end

    context 'with a tag' do
      context 'with an existing branch' do
        let(:params) { { tag: 'v1.0.0' } }

        it_behaves_like 'composer package publish'
      end

      context 'with a non existing tag' do
        let(:params) { { tag: 'non-existing-tag' } }
        let(:headers) { build_basic_auth_header(user.username, personal_access_token.token) }

        before do
          stub_licensed_features(packages: true)
        end

        it_behaves_like 'process Composer api request', :developer, :not_found
      end
    end

    context 'with a branch' do
      context 'with an existing branch' do
        let(:params) { { branch: 'feature' } }

        it_behaves_like 'composer package publish'
      end

      context 'with a non existing branch' do
        let(:params) { { branch: 'non-existing-branch' } }
        let(:headers) { build_basic_auth_header(user.username, personal_access_token.token) }

        before do
          stub_licensed_features(packages: true)
        end

        it_behaves_like 'process Composer api request', :developer, :not_found
      end
    end
  end
end
