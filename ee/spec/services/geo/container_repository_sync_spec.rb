# frozen_string_literal: true

require 'spec_helper'

describe Geo::ContainerRepositorySync, :geo do
  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:container_repository) do
    create(:container_repository, name: 'my_image', project: project)
  end

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')

    stub_registry_replication_config(enabled: true,
                                     primary_api_url: 'http://primary.registry.gitlab')

    stub_request(:get, "http://registry.gitlab/v2/group/test/my_image/tags/list")
      .with(
        headers: {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => 'bearer token'
          })
      .to_return(
        status: 200,
        body: JSON.dump(tags: %w(obsolete)),
        headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "http://primary.registry.gitlab/v2/group/test/my_image/tags/list")
      .with(
        headers: { 'Authorization' => 'bearer pull-token' })
      .to_return(
        status: 200,
        body: JSON.dump(tags: %w(tag-to-sync)),
        headers: { 'Content-Type' => 'application/json' })

    stub_request(:head, "http://primary.registry.gitlab/v2/group/test/my_image/manifests/tag-to-sync")
      .with(
        headers: {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => 'bearer pull-token'
        })
      .to_return(status: 200, body: "", headers: { 'docker-content-digest' => 'sha256:ccccc' })

    stub_request(:head, "http://registry.gitlab/v2/group/test/my_image/manifests/obsolete")
      .with(
        headers: {
          'Accept' => 'application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json',
          'Authorization' => 'bearer token'
        })
      .to_return(status: 200, body: "", headers: { 'docker-content-digest' => 'sha256:aaaaa' })
  end

  describe 'execute' do
    it 'determines list of tags to sync and to remove correctly' do
      expect(container_repository).to receive(:delete_tag_by_digest).with('sha256:aaaaa')
      expect_any_instance_of(described_class).to receive(:sync_tag)

      described_class.new(container_repository).execute
    end
  end
end
