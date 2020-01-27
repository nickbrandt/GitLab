# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::FixProjectsWithoutProjectFeature, :migration, schema: 2020_01_27_111840 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  let(:namespace) { namespaces.create(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:projects_without_feature) { [projects.create!(namespace_id: namespace.id), projects.create!(namespace_id: namespace.id)] }

  before do
    project_features.create({ project_id: project.id, pages_access_level: 20 })
  end

  subject { described_class.new.perform(*project_range) }

  def project_feature_records
    ActiveRecord::Base.connection.select_all('SELECT project_id FROM project_features ORDER BY project_id').map { |e| e['project_id'] }
  end

  def project_range
    ActiveRecord::Base.connection.select_one('SELECT MIN(id), MAX(id) FROM projects').values
  end

  it 'creates a default ProjectFeature for projects without it' do
    expect { subject }.to change { project_feature_records }.from([project.id]).to([project.id, *projects_without_feature.map(&:id)])
  end

  it 'sets created_at/updated_at timestamps' do
    subject

    offenders = ActiveRecord::Base.connection.select_all('SELECT 1 FROM project_features WHERE created_at IS NULL or updated_at IS NULL')

    expect(offenders).to be_empty
  end
end
