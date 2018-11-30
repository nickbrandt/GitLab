# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20181017131623_add_missing_geo_even_log_indexes.rb')

describe AddMissingGeoEvenLogIndexes, :migration do
  let(:namespace) { table(:namespaces).create(path: 'ns', name: 'Namespace') }
  let(:project) { table(:projects).create(namespace_id: namespace.id, path: 'pj') }
  let(:geo_event_log) { table(:geo_event_log) }

  let(:updated_event) do
    table(:geo_repository_updated_events).create(
      project_id: project.id,
      source: 0,
      branches_affected: 0,
      tags_affected: 0)
  end

  let(:hashed_attachment_event) do
    table(:geo_hashed_storage_attachments_events).create(
      project_id: project.id,
      old_attachments_path: '/tmp/foo/bar',
      new_attachments_path: '/tmp/foo/baz')
  end

  describe '#up' do
    it 'adds indexes' do
      schema_migrate_up!
    end
  end

  describe '#down' do
    it 'rolls back indexes' do
      schema_migrate_down!
    end
  end
end
