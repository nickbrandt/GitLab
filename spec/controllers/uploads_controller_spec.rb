# frozen_string_literal: true

require 'spec_helper'
shared_examples 'content 5 min private cached with revalidation' do
  it 'ensures content will not be cached without revalidation' do
    expect(subject['Cache-Control']).to eq('max-age=300, private, must-revalidate')
  end
end

shared_examples 'content not cached' do
  it 'ensures content will not be cached without revalidation' do
    expect(subject['Cache-Control']).to eq('max-age=0, private, must-revalidate')
  end
end

shared_examples 'content publicly cached' do
  it 'ensures content is publicly cached' do
    expect(subject['Cache-Control']).to eq('max-age=300, public')
  end
end

describe UploadsController do
  include WorkhorseHelpers

  let!(:user) { create(:user, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

  describe 'POST #authorize' do
    let(:uploader_class) { PersonalFileUploader }
    let(:params) do
      { model: 'personal_snippet', id: model.id }
    end

    it_behaves_like 'handle uploads authorize' do
      let(:model) { create(:personal_snippet, :public) }
    end

    context 'when snippet is secret' do
      let(:model) { create(:personal_snippet, :secret) }

      context 'when the user can admin the snippet' do
        it_behaves_like 'handle uploads authorize'
      end

      context 'when the user cannot admin the snippet' do
        before do
          sign_in(user)
        end

        context 'when the token is not present' do
          it 'returns 404 status' do
            expect(post_authorize.status).to eq(404)
          end
        end

        context 'when the token is not valid' do
          let(:params) do
            { model: 'personal_snippet', id: model.id, token: 'foo' }
          end

          it 'returns 404 status' do
            expect(post_authorize.status).to eq(404)
          end
        end

        context 'when the token is valid' do
          let(:params) do
            { model: 'personal_snippet', id: model.id, token: model.secret_token }
          end

          before do
            post_authorize
          end

          it 'responds with status 200' do
            expect(response.status).to eq 200
          end

          it 'uses the gitlab-workhorse content type' do
            post_authorize

            expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          end
        end
      end
    end
  end

  describe 'POST create' do
    let(:jpg)     { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:txt)     { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }

    context 'snippet uploads' do
      let(:model)   { 'personal_snippet' }
      let(:snippet) { create(:personal_snippet, :public) }

      context 'when a user does not have permissions to upload a file' do
        it "returns 401 when the user is not logged in" do
          create_request

          expect(response).to have_gitlab_http_status(401)
        end

        it "returns 404 when user can't comment on a snippet" do
          private_snippet = create(:personal_snippet, :private)

          sign_in(user)
          create_request(id: private_snippet.id)

          expect(response).to have_gitlab_http_status(404)
        end

        context 'when the snippet is secret' do
          let(:snippet) { create(:personal_snippet, :secret) }

          it "returns 401 when the user is not logged in" do
            create_request

            expect(response).to have_gitlab_http_status(401)
          end
        end
      end

      context 'when a user is logged in' do
        before do
          sign_in(user)
        end

        it "returns an error without file" do
          create_request

          expect(response).to have_gitlab_http_status(422)
        end

        it "returns an error with invalid model" do
          expect { create_request(model: 'invalid') }
            .to raise_error(ActionController::UrlGenerationError)
        end

        it "returns 404 status when object not found" do
          create_request(id: 9999)

          expect(response).to have_gitlab_http_status(404)
        end

        shared_examples 'sucessfully uploads the file' do
          before do
            request
          end

          it 'returns a content with original filename, new link, and correct type.' do
            expect(response.body).to match "\"alt\":\"#{file_name}\""
            expect(response.body).to match "\"url\":\"/uploads"
          end

          it 'creates a corresponding Upload record' do
            upload = Upload.last

            aggregate_failures do
              expect(upload).to exist
              expect(upload.model).to eq snippet
            end
          end
        end

        context 'with valid image' do
          it_behaves_like 'sucessfully uploads the file' do
            let(:request) { create_request(file: jpg)}
            let(:file_name) { 'rails_sample' }
          end

          context 'when the snippet is secret' do
            let(:snippet) { create(:personal_snippet, :secret) }

            context 'when the token is not present' do
              it 'returns 404' do
                create_request(file: jpg)

                expect(response).to have_gitlab_http_status(404)
              end
            end

            context 'when the token is not valid' do
              it 'returns 404' do
                create_request(file: jpg, token: 'foo')

                expect(response).to have_gitlab_http_status(404)
              end
            end

            context 'when the token is valid' do
              it_behaves_like 'sucessfully uploads the file' do
                let(:request) { create_request(file: jpg, token: snippet.secret_token)}
                let(:file_name) { 'rails_sample' }
              end
            end
          end
        end

        context 'with valid non-image file' do
          it_behaves_like 'sucessfully uploads the file' do
            let(:request) { create_request(file: txt)}
            let(:file_name) { 'doc_sample.txt' }
          end

          context 'when the snippet is secret' do
            let(:snippet) { create(:personal_snippet, :secret) }

            context 'when the token is not present' do
              it 'returns 404' do
                create_request(file: txt)

                expect(response).to have_gitlab_http_status(404)
              end
            end

            context 'when the token is not valid' do
              it 'returns 404' do
                create_request(file: txt, token: 'foo')

                expect(response).to have_gitlab_http_status(404)
              end
            end

            context 'when the token is valid' do
              it_behaves_like 'sucessfully uploads the file' do
                let(:request) { create_request(file: txt, token: snippet.secret_token)}
                let(:file_name) { 'doc_sample.txt' }
              end
            end
          end
        end
      end

      def create_request(model: 'personal_snippet', id: snippet.id, file: nil, token: nil)
        params = { model: model, id: id }
        params[:file] = file if file
        params[:token] = token if token

        post :create, params: params, format: :json
      end
    end

    context 'user uploads' do
      let(:model) { 'user' }

      it 'returns 401 when the user has no access' do
        post :create, params: { model: 'user', id: user.id }, format: :json

        expect(response).to have_gitlab_http_status(401)
      end

      context 'when user is logged in' do
        before do
          sign_in(user)
        end

        subject do
          post :create, params: { model: model, id: user.id, file: jpg }, format: :json
        end

        it 'returns a content with original filename, new link, and correct type.' do
          subject

          expect(response.body).to match '\"alt\":\"rails_sample\"'
          expect(response.body).to match "\"url\":\"/uploads/-/system/user/#{user.id}/"
        end

        it 'creates a corresponding Upload record' do
          expect { subject }.to change { Upload.count }

          upload = Upload.last

          aggregate_failures do
            expect(upload).to exist
            expect(upload.model).to eq user
          end
        end

        context 'with valid non-image file' do
          subject do
            post :create, params: { model: model, id: user.id, file: txt }, format: :json
          end

          it 'returns a content with original filename, new link, and correct type.' do
            subject

            expect(response.body).to match '\"alt\":\"doc_sample.txt\"'
            expect(response.body).to match "\"url\":\"/uploads/-/system/user/#{user.id}/"
          end

          it 'creates a corresponding Upload record' do
            expect { subject }.to change { Upload.count }

            upload = Upload.last

            aggregate_failures do
              expect(upload).to exist
              expect(upload.model).to eq user
            end
          end
        end

        it 'returns 404 when given user is not the logged in one' do
          another_user = create(:user)

          post :create, params: { model: model, id: another_user.id, file: txt }, format: :json

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe "GET show" do
    context 'Content-Disposition security measures' do
      let(:project) { create(:project, :public) }

      context 'for PNG files' do
        it 'returns Content-Disposition: inline' do
          note = create(:note, :with_attachment, project: project)
          get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

          expect(response['Content-Disposition']).to start_with('inline;')
        end
      end

      context 'for SVG files' do
        it 'returns Content-Disposition: attachment' do
          note = create(:note, :with_svg_attachment, project: project)
          get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'unsanitized.svg' }

          expect(response['Content-Disposition']).to start_with('attachment;')
        end
      end
    end

    context "when viewing a user avatar" do
      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user is blocked" do
          before do
            user.block
          end

          it "responds with status 401" do
            get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(401)
          end
        end

        context "when the user isn't blocked" do
          it "responds with status 200" do
            get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'user', mounted_as: 'avatar', id: user.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when not signed in" do
        it "responds with status 200" do
          get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

          expect(response).to have_gitlab_http_status(200)
        end

        it_behaves_like 'content publicly cached' do
          subject do
            get :show, params: { model: 'user', mounted_as: 'avatar', id: user.id, filename: 'dk.png' }

            response
          end
        end
      end
    end

    context "when viewing a project avatar" do
      let!(:project) { create(:project, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "responds with status 401" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(401)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              project.add_maintainer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
                project.add_maintainer(user)
              end

              it "responds with status 401" do
                get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(401)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content 5 min private cached with revalidation' do
                subject do
                  get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context "when viewing a group avatar" do
      let!(:group) { create(:group, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

      context "when the group is public" do
        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the group is private" do
        before do
          group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              group.add_developer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
              end

              it "responds with status 401" do
                get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(401)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content 5 min private cached with revalidation' do
                subject do
                  get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context "when viewing a note attachment" do
      let!(:note) { create(:note, :with_attachment) }
      let(:project) { note.project }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content not cached' do
            subject do
              get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content not cached' do
            subject do
              get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "responds with status 401" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(401)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              project.add_maintainer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
                project.add_maintainer(user)
              end

              it "responds with status 401" do
                get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(401)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content not cached' do
                subject do
                  get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context 'Appearance' do
      context 'when viewing a custom header logo' do
        let!(:appearance) { create :appearance, header_logo: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

        context 'when not signed in' do
          it 'responds with status 200' do
            get :show, params: { model: 'appearance', mounted_as: 'header_logo', id: appearance.id, filename: 'dk.png' }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'appearance', mounted_as: 'header_logo', id: appearance.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context 'when viewing a custom logo' do
        let!(:appearance) { create :appearance, logo: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

        context 'when not signed in' do
          it 'responds with status 200' do
            get :show, params: { model: 'appearance', mounted_as: 'logo', id: appearance.id, filename: 'dk.png' }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'appearance', mounted_as: 'logo', id: appearance.id, filename: 'dk.png' }

              response
            end
          end
        end
      end
    end

    context 'original filename or a version filename must match' do
      let!(:appearance) { create :appearance, favicon: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      context 'has a valid filename on the original file' do
        it 'successfully returns the file' do
          get :show, params: { model: 'appearance', mounted_as: 'favicon', id: appearance.id, filename: 'dk.png' }

          expect(response).to have_gitlab_http_status(200)
          expect(response.header['Content-Disposition']).to end_with 'filename="dk.png"'
        end
      end

      context 'has an invalid filename on the original file' do
        it 'returns a 404' do
          get :show, params: { model: 'appearance', mounted_as: 'favicon', id: appearance.id, filename: 'bogus.png' }

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: params, format: :json
  end
end
