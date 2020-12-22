# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateSecuritySetting, schema: 20201207133126 do
  let(:projects) { table(:projects) }
  let(:settings) { table(:project_security_settings) }
  let(:namespaces) { table(:namespaces) }

  it 'adds setting object for existing projects' do
    namespace = namespaces.create!(name: 'test', path: 'test')
    projects.create!(id: 12, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')
    projects.create!(id: 13, namespace_id: namespace.id, name: 'sec_gitlab', path: 'sec_gitlab')
    projects.create!(id: 14, namespace_id: namespace.id, name: 'my_gitlab', path: 'my_gitlab')
    settings.create(project_id: 13)

    expect { described_class.new.perform([12, 13, 14]) }.to change { settings.count }.from(1).to(3)
  end
end
