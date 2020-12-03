# frozen_string_literal: true

RSpec.shared_examples 'Git HTTP requests' do
  include GitHttpHelpers

  shared_examples 'pulls require Basic HTTP Authentication' do
    context "when no credentials are provided" do
      it "responds to downloads with status 401 Unauthorized (no project existence information leak)" do
        download(path) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when only username is provided" do
      it "responds to downloads with status 401 Unauthorized" do
        download(path, user: user.username) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when username and password are provided" do
      context "when authentication fails" do
        it "responds to downloads with status 401 Unauthorized" do
          download(path, user: user.username, password: "wrong-password") do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to start_with('Basic ')
          end
        end
      end

      context "when authentication succeeds" do
        it "does not respond to downloads with status 401 Unauthorized" do
          download(path, user: user.username, password: user.password) do |response|
            expect(response).not_to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to be_nil
          end
        end
      end
    end
  end

  shared_examples 'pushes require Basic HTTP Authentication' do
    context "when no credentials are provided" do
      it "responds to uploads with status 401 Unauthorized (no project existence information leak)" do
        upload(path) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when only username is provided" do
      it "responds to uploads with status 401 Unauthorized" do
        upload(path, user: user.username) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when username and password are provided" do
      context "when authentication fails" do
        it "responds to uploads with status 401 Unauthorized" do
          upload(path, user: user.username, password: "wrong-password") do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to start_with('Basic ')
          end
        end
      end

      context "when authentication succeeds" do
        it "does not respond to uploads with status 401 Unauthorized" do
          upload(path, user: user.username, password: user.password) do |response|
            expect(response).not_to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to be_nil
          end
        end
      end
    end
  end

  shared_examples_for 'pulls are allowed' do
    specify do
      download(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  shared_examples_for 'pushes are allowed' do
    specify :sidekiq_might_not_need_inline do
      upload(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  shared_examples_for 'project path without .git suffix' do
    context "GET info/refs" do
      let(:path) { "/#{repository_path}/info/refs" }

      context "when no params are added" do
        before do
          get path
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs")
        end
      end

      context "when the upload-pack service is requested" do
        let(:params) { { service: 'git-upload-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs?service=#{params[:service]}")
        end
      end

      context "when the receive-pack service is requested" do
        let(:params) { { service: 'git-receive-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs?service=#{params[:service]}")
        end
      end

      context "when the params are anything else" do
        let(:params) { { service: 'git-implode-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the sign-in page" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "POST git-upload-pack" do
      it "fails to find a route" do
        expect { clone_post(repository_path) }.to raise_error(ActionController::RoutingError)
      end
    end

    context "POST git-receive-pack" do
      it "fails to find a route" do
        expect { push_post(repository_path) }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
