require 'spec_helper'

describe API::Projects do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }

  describe 'POST /projects' do
    context 'when importing with mirror attributes' do
      let(:import_url) { generate(:url) }
      let(:mirror_params) do
        {
          name: "Foo",
          mirror: true,
          import_url: import_url,
          mirror_trigger_builds: true
        }
      end

      it 'creates new project with pull mirroring setup' do
        post api('/projects', user), mirror_params

        expect(response).to have_gitlab_http_status(201)
        expect(Project.first).to have_attributes(
          mirror: true,
          import_url: import_url,
          mirror_user_id: user.id,
          mirror_trigger_builds: true
        )
      end

      it 'creates project without mirror settings when repository mirroring feature is disabled' do
        stub_licensed_features(repository_mirrors: false)

        expect { post api('/projects', user), mirror_params }
          .to change { Project.count }.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(Project.first).to have_attributes(
          mirror: false,
          import_url: import_url,
          mirror_user_id: nil,
          mirror_trigger_builds: false
        )
      end

      context 'when pull mirroring is not available' do
        before do
          stub_ee_application_setting(mirror_available: false)
        end

        it 'returns a 403' do
          post api('/projects', user), mirror_params

          expect(response).to have_gitlab_http_status(403)
          expect(json_response["message"]).to eq("Pull mirroring is not available")
        end

        it 'creates project with mirror settings' do
          admin = create(:admin)

          post api('/projects', admin), mirror_params

          expect(response).to have_gitlab_http_status(201)
          expect(Project.first).to have_attributes(
            mirror: true,
            import_url: import_url,
            mirror_user_id: admin.id,
            mirror_trigger_builds: true
          )
        end
      end
    end
  end

  describe 'PUT /projects/:id' do
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      enable_external_authorization_service_check
    end

    it 'updates the classification label when enabled' do
      put(api("/projects/#{project.id}", user), external_authorization_classification_label: 'new label')

      expect(response).to have_gitlab_http_status(200)

      expect(project.reload.external_authorization_classification_label).to eq('new label')
    end

    context 'when updating mirror related attributes' do
      let(:import_url) { generate(:url) }
      let(:mirror_params) do
        {
          mirror: true,
          import_url: import_url,
          mirror_user_id: user.id,
          mirror_trigger_builds: true,
          only_mirror_protected_branches: true,
          mirror_overwrites_diverged_branches: true
        }
      end

      context 'when pull mirroring is not available' do
        before do
          stub_ee_application_setting(mirror_available: false)
        end

        it 'raises an API error' do
          put(api("/projects/#{project.id}", user), mirror_params)

          expect(response).to have_gitlab_http_status(403)
          expect(json_response["message"]).to eq("Pull mirroring is not available")
        end

        it 'updates mirror related attributes when user is admin' do
          admin = create(:admin)
          mirror_params[:mirror_user_id] = admin.id
          project.add_maintainer(admin)

          expect_any_instance_of(EE::Project).to receive(:force_import_job!).once

          put(api("/projects/#{project.id}", admin), mirror_params)

          expect(response).to have_gitlab_http_status(200)
          expect(project.reload).to have_attributes(
            mirror: true,
            import_url: import_url,
            mirror_user_id: admin.id,
            mirror_trigger_builds: true,
            only_mirror_protected_branches: true,
            mirror_overwrites_diverged_branches: true
          )
        end
      end

      it 'updates mirror related attributes' do
        expect_any_instance_of(EE::Project).to receive(:force_import_job!).once

        put(api("/projects/#{project.id}", user), mirror_params)

        expect(response).to have_gitlab_http_status(200)
        expect(project.reload).to have_attributes(
          mirror: true,
          import_url: import_url,
          mirror_user_id: user.id,
          mirror_trigger_builds: true,
          only_mirror_protected_branches: true,
          mirror_overwrites_diverged_branches: true
        )
      end

      it 'renders an API error when mirror user is invalid' do
        invalid_mirror_user = create(:user)
        project.add_developer(invalid_mirror_user)
        mirror_params[:mirror_user_id] = invalid_mirror_user.id

        put(api("/projects/#{project.id}", user), mirror_params)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response["message"]).to eq("Invalid mirror user")
      end

      it 'returns 403 when the user does not have access to mirror settings' do
        developer = create(:user)
        project.add_developer(developer)

        put(api("/projects/#{project.id}", developer), mirror_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 403 when the project is unable to setup repository mirroring' do
        stub_licensed_features(repository_mirrors: false)

        put(api("/projects/#{project.id}", user), mirror_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
