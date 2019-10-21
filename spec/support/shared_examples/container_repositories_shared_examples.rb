# frozen_string_literal: true

shared_examples 'rejected container repository access' do |user_type, status|
  context "for #{user_type}" do
    let(:api_user) { users[user_type] }

    it "returns #{status}" do
      subject

      expect(response).to have_gitlab_http_status(status)
    end
  end
end

shared_examples 'returns repositories for allowed users' do |user_type, scope|
  context "for #{user_type}" do
    it 'returns a list of repositories' do
      subject

      expect(json_response.length).to eq(2)
      expect(json_response.map { |repository| repository['id'] }).to contain_exactly(
        root_repository.id, test_repository.id)
      expect(response.body).not_to include('tags')
    end

    it 'returns a matching schema' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('registry/repositories')
    end

    context 'with tags param' do
      let(:url) { "/#{scope}s/#{object.id}/registry/repositories?tags=true" }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA latest), with_manifest: true)
        stub_container_registry_tags(repository: test_repository.path, tags: %w(rootA latest), with_manifest: true)
      end

      it 'returns a list of repositories and their tags' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.map { |repository| repository['id'] }).to contain_exactly(
          root_repository.id, test_repository.id)
        expect(response.body).to include('tags')
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repositories')
      end
    end
  end
end

shared_examples 'schedules cleanup of tags repository with lease' do |perform_async_times|
  context 'called multiple times in one hour', :clean_gitlab_redis_shared_state do
    it 'returns 400 with an error message' do
      stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
      subject

      expect(response).to have_gitlab_http_status(400)
      expect(response.body).to include('This request has already been made.')
    end

    it 'executes service only for the first time' do
      expect(CleanupContainerRepositoryWorker).to receive(:perform_async).exactly(perform_async_times).times

      2.times { subject }
    end
  end
end
