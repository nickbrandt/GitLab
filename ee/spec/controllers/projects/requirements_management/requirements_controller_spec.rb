# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RequirementsManagement::RequirementsController do
  let_it_be(:user) { create(:user) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    context 'private project' do
      let(:project) { create(:project) }

      context 'with authorized user' do
        before do
          project.add_developer(user)
          sign_in(user)
        end

        context 'when feature is available' do
          before do
            stub_licensed_features(requirements: true)
          end

          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        context 'when feature is not available' do
          before do
            stub_licensed_features(requirements: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with unauthorized user' do
        before do
          sign_in(user)
        end

        context 'when feature is available' do
          before do
            stub_licensed_features(requirements: true)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with anonymous user' do
        it 'returns 302' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'public project' do
      let(:project) { create(:project, :public) }

      before do
        stub_licensed_features(requirements: true)
      end

      context 'with requirements disabled' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::DISABLED })
          project.add_developer(user)
          sign_in(user)
        end

        it_behaves_like 'response with 404 status'
      end

      context 'with requirements visible to project members' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::PRIVATE })
        end

        context 'with authorized user' do
          before do
            project.add_developer(user)
            sign_in(user)
          end

          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        context 'with unauthorized user' do
          before do
            sign_in(user)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with requirements visible to everyone' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::ENABLED })
        end

        context 'with anonymous user' do
          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end
      end
    end
  end

  describe 'POST #import_csv' do
    let_it_be(:project) { create(:project, :public) }
    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

    subject { import_csv }

    context 'unauthorized' do
      context 'when user is not signed in' do
        before do
          sign_out(:user)
        end

        it_behaves_like 'response with 404 status'
      end

      context 'with project members with guest role' do
        before do
          sign_in(user)
          project.add_guest(user)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    context 'authorized' do
      before do
        sign_in(user)
        project.add_reporter(user)
      end

      context 'when requirements feature is available' do
        before do
          stub_licensed_features(requirements: true)
        end

        context 'when import_requirements_csv feature flag is enabled' do
          before do
            stub_feature_flags(import_requirements_csv: true)
          end

          it "returns 302 for project members with reporter role" do
            subject

            expect(flash[:notice]).to eq(_("Your requirements are being imported. Once finished, you'll get a confirmation email."))
            expect(response).to redirect_to(project_requirements_management_requirements_path(project))
          end

          it "shows error when upload fails" do
            expect_next_instance_of(UploadService) do |upload_service|
              expect(upload_service).to receive(:execute).and_return(nil)
            end

            subject

            expect(flash[:alert]).to include(_('File upload error.'))
            expect(response).to redirect_to(project_requirements_management_requirements_path(project))
          end
        end

        context 'when import_requirements_csv feature flag is disabled' do
          before do
            stub_feature_flags(import_requirements_csv: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'when requirements feature is available' do
        before do
          stub_licensed_features(requirements: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    def import_csv
      post :import_csv, params: { namespace_id: project.namespace.to_param,
                                  project_id: project.to_param,
                                  file: file }
    end
  end
end
