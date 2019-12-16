# frozen_string_literal: true

require 'spec_helper'

describe "Git HTTP requests (Geo)", :geo do
  include TermsHelper
  include ::EE::GeoHelpers
  include GitHttpHelpers
  include WorkhorseHelpers
  using RSpec::Parameterized::TableSyntax

  set(:project) { create(:project, :repository, :private) }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  # Ensure the token always comes from the real time of the request
  let(:auth_token) { Gitlab::Geo::BaseRequest.new(scope: project.full_path).authorization }
  let!(:user) { create(:user) }
  let!(:user_without_any_access) { create(:user) }
  let!(:user_without_push_access) { create(:user) }
  let!(:key) { create(:key, user: user) }
  let!(:key_for_user_without_any_access) { create(:key, user: user_without_any_access) }
  let!(:key_for_user_without_push_access) { create(:key, user: user_without_push_access) }

  let(:env) { valid_geo_env }
  let(:auth_token_with_invalid_scope) { Gitlab::Geo::BaseRequest.new(scope: "invalid").authorization }

  before do
    project.add_maintainer(user)
    project.add_guest(user_without_push_access)

    stub_licensed_features(geo: true)
    stub_current_geo_node(current_node)

    # Current Geo node must be stubbed before this is instantiated
    auth_token
  end

  shared_examples_for 'Geo request' do
    subject do
      make_request
      response
    end

    context 'post-dated Geo JWT token' do
      it { travel_to(11.minutes.ago) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'expired Geo JWT token' do
      it { travel_to(Time.now + 11.minutes) { is_expected.to have_gitlab_http_status(:unauthorized) } }
    end

    context 'invalid Geo JWT token' do
      let(:env) { geo_env("GL-Geo xxyyzz:12345") }

      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'valid Geo JWT token' do
      it 'returns an OK response' do
        is_expected.to have_gitlab_http_status(:ok)

        expect(response.content_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response).to include('ShowAllRefs' => true)
      end
    end

    context 'no Geo JWT token' do
      let(:env) { workhorse_internal_api_request_header }

      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'Geo is unlicensed' do
      before do
        stub_licensed_features(geo: false)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end
  end

  context 'when current node is a secondary' do
    let(:current_node) { secondary }

    set(:project) { create(:project, :repository, :private) }

    describe 'GET info_refs' do
      context 'git pull' do
        def make_request
          get "/#{project.full_path}.git/info/refs", params: { service: 'git-upload-pack' }, headers: env
        end

        it_behaves_like 'Geo request'

        context 'when terms are enforced' do
          before do
            enforce_terms
          end

          it_behaves_like 'Geo request'
        end
      end

      context 'git push' do
        def make_request
          get url, params: { service: 'git-receive-pack' }, headers: env
        end

        let(:url) { "/#{project.full_path}.git/info/refs" }

        subject do
          make_request
          response
        end

        it 'redirects to the primary' do
          is_expected.to have_gitlab_http_status(:redirect)
          redirect_location = "#{redirected_primary_url}?service=git-receive-pack"
          expect(subject.header['Location']).to eq(redirect_location)
        end
      end
    end

    describe 'POST git_upload_pack' do
      def make_request
        post "/#{project.full_path}.git/git-upload-pack", params: {}, headers: env
      end

      it_behaves_like 'Geo request'

      context 'when terms are enforced' do
        before do
          enforce_terms
        end

        it_behaves_like 'Geo request'
      end
    end

    context 'git-lfs' do
      context 'API' do
        describe 'POST batch' do
          def make_request
            post url, params: args, headers: env
          end

          let(:args) { {} }
          let(:url) { "/#{project.full_path}.git/info/lfs/objects/batch" }

          subject do
            make_request
            response
          end

          before do
            allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
            project.update_attribute(:lfs_enabled, true)
            env['Content-Type'] = LfsRequest::CONTENT_TYPE
          end

          context 'operation upload' do
            let(:args) { { 'operation' => 'upload' }.to_json }

            context 'with the correct git-lfs version' do
              before do
                env['User-Agent'] = 'git-lfs/2.4.2 (GitHub; darwin amd64; go 1.10.2)'
              end

              it 'redirects to the primary' do
                is_expected.to have_gitlab_http_status(:redirect)
                redirect_location = "#{redirected_primary_url}"
                expect(subject.header['Location']).to eq(redirect_location)
              end
            end

            context 'with an incorrect git-lfs version' do
              where(:description, :version) do
                'outdated' | 'git-lfs/2.4.1'
                'unknown'  | 'git-lfs'
              end

              with_them do
                context "that is #{description}" do
                  before do
                    env['User-Agent'] = "#{version} (GitHub; darwin amd64; go 1.10.2)"
                  end

                  it 'is forbidden' do
                    is_expected.to have_gitlab_http_status(:forbidden)
                    expect(json_response['message']).to match(/You need git-lfs version 2.4.2/)
                  end
                end
              end
            end
          end

          context 'operation download' do
            let(:user) { create(:user) }
            let(:authorization) { ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password) }
            let(:lfs_object) { create(:lfs_object, :with_file) }
            let(:args) do
              {
                'operation' => 'download',
                'objects' => [{ 'oid' => lfs_object.oid, 'size' => lfs_object.size }]
              }.to_json
            end

            before do
              project.add_maintainer(user)
              env['Authorization'] = authorization
            end

            it 'is handled by the secondary' do
              is_expected.to have_gitlab_http_status(:ok)
            end

            where(:description, :version) do
              'outdated' | 'git-lfs/2.4.1'
              'unknown'  | 'git-lfs'
            end

            with_them do
              context "with an #{description} git-lfs version" do
                before do
                  env['User-Agent'] = "#{version} (GitHub; darwin amd64; go 1.10.2)"
                end

                it 'is handled by the secondary' do
                  is_expected.to have_gitlab_http_status(:ok)
                end
              end
            end
          end
        end
      end

      context 'Locks API' do
        where(:description, :path, :args) do
          'create' | 'info/lfs/locks'          | {}
          'verify' | 'info/lfs/locks/verify'   | {}
          'unlock' | 'info/lfs/locks/1/unlock' | { id: 1 }
        end

        with_them do
          describe "POST #{description}" do
            def make_request
              post url, params: args, headers: env
            end

            let(:url) { "/#{project.full_path}.git/#{path}" }

            subject do
              make_request
              response
            end

            it 'redirects to the primary' do
              is_expected.to have_gitlab_http_status(:redirect)
              redirect_location = "#{redirected_primary_url}"
              expect(subject.header['Location']).to eq(redirect_location)
            end
          end
        end
      end
    end

    def redirected_primary_url
      "#{primary.url.chomp('/')}#{::Gitlab::Geo::GitPushHttp::PATH_PREFIX}/#{secondary.id}#{url}"
    end
  end

  context 'when current node is the primary', :use_clean_rails_memory_store_caching do
    let(:current_node) { primary }

    describe 'POST git_receive_pack' do
      subject do
        make_request
        response
      end

      context 'when HTTP redirected from a secondary node' do
        def make_request
          post url, headers: auth_env(user.username, user.password, nil)
        end

        let(:identifier) { "user-#{user.id}" }
        let(:gl_repository) { "project-#{project.id}" }
        let(:url) { "#{::Gitlab::Geo::GitPushHttp::PATH_PREFIX}/#{secondary.id}/#{project.full_path}.git/git-receive-pack" }

        # The bigger picture request flow relevant to this feature is:
        #
        #   * The HTTP request hits NGINX
        #   * Then Workhorse
        #   * Then Rails (the scope of request tests is limited to this line item)
        #   * Rails responds OK to Workhorse
        #   * Workhorse connects to Gitaly: SmartHTTP Service, ReceivePack RPC
        #   * In a pre-receive hook, Gitaly makes a request to Rails' POST /api/v4/internal/allowed
        #   * Rails says OK
        #   * In a post-receive hook, Gitaly makes a request to Rails' POST /api/v4/internal/post_receive
        #   * Rails responds to Gitaly, including a collection of messages, which includes the replication lag message
        #   * Gitaly outputs the messages in the stream of Proto messages
        #   * Pipe the output through Workhorse and NGINX
        #
        # See https://gitlab.com/gitlab-org/gitlab/issues/9195
        #
        it 'stores the secondary node ID so the internal API post_receive request can generate the replication lag message' do
          is_expected.to have_gitlab_http_status(:ok)

          stored_node = ::Gitlab::Geo::GitPushHttp.new(identifier, gl_repository).fetch_referrer_node
          expect(stored_node).to eq(secondary)
        end
      end

      context 'when proxying an SSH request from a secondary node' do
        def make_request
          post url, params: {}, headers: env
        end

        let(:url) { "/#{project.full_path}.git/git-receive-pack" }

        before do
          env['Geo-GL-Id'] = geo_gl_id
        end

        context 'when gl_id is incorrectly provided via HTTP headers' do
          where(:geo_gl_id) do
            [
              nil,
              ''
            ]
          end

          with_them do
            it 'returns a 403' do
              is_expected.to have_gitlab_http_status(:forbidden)
              expect(response.body).to eql('You are not allowed to upload code for this project.')
            end
          end
        end

        context 'when gl_id is provided via HTTP headers' do
          context 'but is invalid' do
            where(:geo_gl_id) do
              [
                'key-999',
                'key-1',
                'key-999',
                'junk',
                'junk-1',
                'kkey-1'
              ]
            end

            with_them do
              it 'returns a 403' do
                is_expected.to have_gitlab_http_status(:forbidden)
                expect(response.body).to eql('Geo push user is invalid.')
              end
            end
          end

          context 'and is valid' do
            context 'but the user has no access' do
              let(:geo_gl_id) { "key-#{key_for_user_without_any_access.id}" }

              it 'returns a 404' do
                is_expected.to have_gitlab_http_status(:not_found)
                expect(response.body).to eql('The project you were looking for could not be found.')
              end
            end

            context 'but the user does not have push access' do
              let(:geo_gl_id) { "key-#{key_for_user_without_push_access.id}" }

              it 'returns a 403' do
                is_expected.to have_gitlab_http_status(:forbidden)
                expect(response.body).to eql('You are not allowed to push code to this project.')
              end
            end

            context 'and the user has push access' do
              let(:geo_gl_id) { "key-#{key.id}" }

              it 'returns a 200' do
                is_expected.to have_gitlab_http_status(:ok)
                expect(json_response['GL_ID']).to match("user-#{user.id}")
                expect(json_response['GL_REPOSITORY']).to match(Gitlab::GlRepository::PROJECT.identifier_for_subject(project))
              end
            end
          end
        end
      end
    end

    context 'repository does not exist' do
      subject do
        make_request
        response
      end

      def make_request
        full_path = project.full_path
        project.destroy

        get "/#{full_path}.git/info/refs", params: { service: 'git-upload-pack' }, headers: env
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'invalid scope' do
      subject do
        make_request
        response
      end

      def make_request
        get "/#{repository_path}.git/info/refs", params: { service: 'git-upload-pack' }, headers: env
      end

      shared_examples_for 'unauthorized because of invalid scope' do
        it { is_expected.to have_gitlab_http_status(:unauthorized) }

        it 'returns correct error' do
          expect(subject.parsed_body).to eq('Geo JWT authentication failed: Unauthorized scope')
        end
      end

      context 'invalid scope of Geo JWT token' do
        let(:repository_path) { project.full_path }
        let(:env) { geo_env(auth_token_with_invalid_scope) }

        include_examples 'unauthorized because of invalid scope'
      end

      context 'Geo JWT token scopes for wiki and repository are not interchangeable' do
        context 'for a repository but using a wiki scope' do
          let(:repository_path) { project.full_path }
          let(:scope) { project.wiki.full_path }
          let(:auth_token_with_valid_wiki_scope) { Gitlab::Geo::BaseRequest.new(scope: scope).authorization }
          let(:env) { geo_env(auth_token_with_valid_wiki_scope) }

          include_examples 'unauthorized because of invalid scope'
        end

        context 'for a wiki but using a repository scope' do
          let(:project) { create(:project, :wiki_repo) }
          let(:repository_path) { project.wiki.full_path }
          let(:scope) { project.full_path }
          let(:auth_token_with_valid_repository_scope) { Gitlab::Geo::BaseRequest.new(scope: scope).authorization }
          let(:env) { geo_env(auth_token_with_valid_repository_scope) }

          include_examples 'unauthorized because of invalid scope'
        end
      end
    end

    context 'IP allowed settings' do
      subject do
        make_request
        response
      end

      def make_request
        get "/#{repository_path}.git/info/refs", params: { service: 'git-upload-pack' }, headers: env
      end

      let(:repository_path) { project.full_path }

      it 'returns unauthorized error' do
        stub_application_setting(geo_node_allowed_ips: '192.34.34.34')

        is_expected.to have_gitlab_http_status(:unauthorized)
        expect(subject.parsed_body).to eq('Request from this IP is not allowed')
      end

      it 'returns success response' do
        stub_application_setting(geo_node_allowed_ips: '127.0.0.1')

        is_expected.to have_gitlab_http_status(:success)
      end
    end
  end

  def valid_geo_env
    geo_env(auth_token)
  end

  def geo_env(authorization)
    workhorse_internal_api_request_header.tap do |env|
      env['HTTP_AUTHORIZATION'] = authorization
    end
  end
end
