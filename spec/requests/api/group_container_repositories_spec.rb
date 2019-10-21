# frozen_string_literal: true

require 'spec_helper'

describe API::GroupContainerRepositories do
  include ExclusiveLeaseHelpers

  set(:group) { create(:group, :private) }
  set(:project) { create(:project, :private, group: group) }
  set(:maintainer) { create(:user) }
  set(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }

  let(:root_repository) { create(:container_repository, :root, project: project) }
  let(:test_repository) { create(:container_repository, project: project) }

  let(:users) do
    {
      anonymous: nil,
      guest: guest,
      reporter: reporter
    }
  end

  let(:api_user) { reporter }

  before do
    group.add_maintainer(maintainer)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_guest(guest)

    stub_feature_flags(container_registry_api: true)
    stub_container_registry_config(enabled: true)

    root_repository
    test_repository
  end

  describe 'GET /groups/:id/registry/repositories' do
    let(:url) { "/groups/#{group.id}/registry/repositories" }

    subject { get api(url, api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found

    it_behaves_like 'returns repositories for allowed users', :reporter, 'group' do
      let(:object) { group }
    end

    context 'with invalid group id' do
      let(:url) { '/groups/123412341234/registry/repositories' }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /groups/:id/registry/repositories' do
    let(:url) { "/groups/#{group.id}/registry/repositories/tags" }

    subject { delete api(url, api_user), params: params }

    context 'disallowed' do
      let(:params) do
        { name_regex: 'v10.*' }
      end

      it_behaves_like 'rejected container repository access', :reporter, :forbidden
      it_behaves_like 'rejected container repository access', :developer, :not_found
      it_behaves_like 'rejected container repository access', :anonymous, :not_found
    end

    context 'for maintainer' do
      let(:api_user) { maintainer }

      context 'without required parameters' do
        let(:params) { }

        it 'returns bad request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with invalid group id' do
        let(:params) { }
        let(:url) { "/groups/123412341234/registry/repositories/tags" }

        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'passes all declared parameters' do
        let(:params) do
          { name_regex: 'v10.*',
            keep_n: 100,
            older_than: '1 day',
            other: 'some value' }
        end

        let(:worker_params) do
          { name_regex: 'v10.*',
            keep_n: 100,
            older_than: '1 day' }
        end

        let(:lease_key) { "container_repository:cleanup_tags:group:#{group.id}" }

        it 'schedules cleanup of tags repository' do
          stub_exclusive_lease(lease_key, timeout: 1.hour)
          expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
            .with(maintainer.id, root_repository.id, worker_params)
          expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
            .with(maintainer.id, test_repository.id, worker_params)

          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end

        context 'called multiple times in one hour', :clean_gitlab_redis_shared_state do
          it 'returns 400 with an error message' do
            stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
            subject

            expect(response).to have_gitlab_http_status(400)
            expect(response.body).to include('This request has already been made.')
          end

          it 'executes service only for the first time' do
            expect(CleanupContainerRepositoryWorker).to receive(:perform_async).exactly(2).times

            2.times { subject }
          end
        end
      end
    end
  end
end
