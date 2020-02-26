# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20200221064734_add_unique_indexes_on_services.rb')

describe AddUniqueIndexesOnServices, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:services) { table(:services) }
    let(:projects) { table(:projects) }
    let(:project_1) { projects.create!(namespace_id: 1) }
    let(:project_2) { projects.create!(namespace_id: 1) }

    before do
      services.create!(project_id: project_1.id, type: 'Service')
      services.create!(project_id: project_1.id, type: 'Service')
      services.create!(project_id: project_2.id, type: 'Service')
    end

    it 'creates a unique index on project_id and type and deletes duplicated services' do
      expect { migration.up }.to change { migration.index_exists?(:services, [:type, :project_id], name: :index_services_on_type_and_project_id) }.from(false).to(true)
        .and change { services.count }.from(3).to(2)

      expect(services.all.pluck(:id)).to eq([1, 3])
    end
  end

  describe '#down' do
    it 'removes the unique index on type' do
      migration.up

      expect { migration.down }.to change { migration.index_exists?(:services, [:type, :project_id], name: :index_services_on_type_and_project_id) }.from(true).to(false)
    end
  end
end
