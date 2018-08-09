require 'spec_helper'

describe API::Projects do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  describe 'PUT /projects/:id' do
    context 'when updating external classification' do
      before do
        enable_external_authorization_service_check
      end

      it 'updates the classification label when enabled' do
        put(api("/projects/#{project.id}", user), external_authorization_classification_label: 'new label')

        expect(response).to have_gitlab_http_status(200)

        expect(project.reload.external_authorization_classification_label).to eq('new label')
      end
    end

    context 'when updating repository storage' do
      let(:unknown_storage) { 'new-storage' }
      let(:new_project) { create(:project, :repository, namespace: user.namespace) }

      context 'as a user' do
        it 'returns 200 but does not change repository_storage' do
          expect do
            Sidekiq::Testing.fake! do
              put(api("/projects/#{new_project.id}", user), repository_storage: unknown_storage, issues_enabled: false)
            end
          end.not_to change(ProjectUpdateRepositoryStorageWorker.jobs, :size)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['issues_enabled']).to eq(false)
          expect(new_project.reload.repository.storage).to eq('default')
        end
      end

      context 'as an admin' do
        let(:admin) { create(:admin) }

        it 'returns 500 when repository storage is unknown' do
          put(api("/projects/#{new_project.id}", admin), repository_storage: unknown_storage)

          expect(response).to have_gitlab_http_status(500)
          expect(json_response['message']).to match('ArgumentError')
        end

        it 'returns 200 when repository storage has changed' do
          stub_storage_settings('extra' => { 'path' => 'tmp/tests/extra_storage' })

          expect do
            Sidekiq::Testing.fake! do
              put(api("/projects/#{new_project.id}", admin), repository_storage: 'extra')
            end
          end.to change(ProjectUpdateRepositoryStorageWorker.jobs, :size).by(1)

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end
end
