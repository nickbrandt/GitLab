# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::ResetChecksumFromProjectRepositoryStates, :migration, schema: 20180914195058 do
  describe '#perform' do
    let(:users) { table(:users) }
    let(:projects) { table(:projects) }
    let(:repository_states) { table(:project_repository_states) }

    def create_repository_state(params = {})
      attrs = {
        repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
        last_repository_verification_failure: nil,
        repository_retry_count: nil,
        repository_retry_at: nil,
        wiki_verification_checksum: 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef',
        last_wiki_verification_failure: nil,
        wiki_retry_count: nil,
        wiki_retry_at: nil
      }.merge(params)

      repository_states.create!(attrs)
    end

    it 'processes all repository states in batch' do
      users.create!(email: 'test@example.com', projects_limit: 100, username: 'test')
      projects.create!(id: 1, name: 'project-1', path: 'project-1', visibility_level: 0, namespace_id: 1)
      projects.create!(id: 2, name: 'project-2', path: 'project-2', visibility_level: 0, namespace_id: 1)
      projects.create!(id: 3, name: 'project-3', path: 'project-3', visibility_level: 0, namespace_id: 1)

      repository_state_1 = create_repository_state(project_id: 1)

      repository_state_2 = create_repository_state(
        project_id: 2,
        wiki_verification_checksum: nil,
        last_wiki_verification_failure: 'Could not calculate the checksum',
        wiki_retry_count: 1,
        wiki_retry_at: Time.now + 5.minutes
      )

      repository_state_3 = create_repository_state(project_id: 3)

      subject.perform(repository_state_1.project_id, repository_state_2.project_id)

      expect(repository_state_1.reload).to have_attributes(
        repository_verification_checksum: be_nil,
        wiki_verification_checksum: be_nil,
        last_repository_verification_failure: be_nil,
        last_wiki_verification_failure: be_nil,
        repository_retry_at: be_nil,
        wiki_retry_at: be_nil,
        repository_retry_count: be_nil,
        wiki_retry_count: be_nil
      )

      expect(repository_state_2.reload).to have_attributes(
        repository_verification_checksum: be_nil,
        wiki_verification_checksum: be_nil,
        last_repository_verification_failure: be_nil,
        last_wiki_verification_failure: be_nil,
        repository_retry_at: be_nil,
        wiki_retry_at: be_nil,
        repository_retry_count: be_nil,
        wiki_retry_count: be_nil
      )

      expect(repository_state_3.reload).to have_attributes(
        repository_verification_checksum: be_present,
        wiki_verification_checksum: be_present
      )
    end
  end
end
