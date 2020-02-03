# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::FixProjectsWithoutProjectFeature, :migration, schema: 2020_01_27_111840 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }

  let(:namespace) { namespaces.create(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:projects_without_feature) do
    [
      projects.create!(namespace_id: namespace.id, visibility_level: 0),
      projects.create!(namespace_id: namespace.id, visibility_level: 20)
    ]
  end

  let(:public_project_without_feature) { projects_without_feature.last }
  let(:private_project_without_feature) { projects_without_feature.first }

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

  it 'creates a ProjectFeature for projects without it' do
    expect { subject }.to change { project_feature_records }.from([project.id]).to([project.id, *projects_without_feature.map(&:id)])
  end

  it 'creates ProjectFeature records with default values for a public project' do
    subject

    project_id = public_project_without_feature.id
    record = ActiveRecord::Base.connection.select_one("SELECT * FROM project_features WHERE id=#{project_id}")

    expect(record.except('id', 'project_id', 'created_at', 'updated_at')).to eq(
      {
        "merge_requests_access_level" => 20,
        "issues_access_level" => 20,
        "wiki_access_level" => 20,
        "snippets_access_level" => 20,
        "builds_access_level" => 20,
        "repository_access_level" => 20,
        "pages_access_level" => 20,
        "forking_access_level" => 20
      }
    )
  end

  it 'creates ProjectFeature records with default values for a private project' do
    subject

    project_id = private_project_without_feature.id
    record = ActiveRecord::Base.connection.select_one("SELECT * FROM project_features WHERE id=#{project_id}")

    expect(record.except('id', 'project_id', 'created_at', 'updated_at')).to eq(
      {
        "merge_requests_access_level" => 20,
        "issues_access_level" => 20,
        "wiki_access_level" => 20,
        "snippets_access_level" => 20,
        "builds_access_level" => 20,
        "repository_access_level" => 20,
        "pages_access_level" => 10,
        "forking_access_level" => 20
      }
    )
  end

  context 'when access control to pages is forced' do
    before do
      allow(::Gitlab::Pages).to receive(:access_control_is_forced?).and_return(true)
    end

    it 'creates ProjectFeature records with default values for a public project' do
      subject

      project_id = public_project_without_feature.id
      record = ActiveRecord::Base.connection.select_one("SELECT * FROM project_features WHERE id=#{project_id}")

      expect(record.except('id', 'project_id', 'created_at', 'updated_at')).to eq(
        {
          "merge_requests_access_level" => 20,
          "issues_access_level" => 20,
          "wiki_access_level" => 20,
          "snippets_access_level" => 20,
          "builds_access_level" => 20,
          "repository_access_level" => 20,
          "pages_access_level" => 10,
          "forking_access_level" => 20
        }
      )
    end
  end

  it 'sets created_at/updated_at timestamps' do
    subject

    offenders = ActiveRecord::Base.connection.select_all('SELECT 1 FROM project_features WHERE created_at IS NULL or updated_at IS NULL')

    expect(offenders).to be_empty
  end
end
