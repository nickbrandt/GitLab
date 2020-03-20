# frozen_string_literal: true

RSpec.shared_examples 'EE saves project tree successfully' do |ndjson_enabled|
  include ::ImportExport::CommonUtil

  let(:full_path) do
    project_tree_saver.save

    if ndjson_enabled == true
      File.join(shared.export_path, 'tree')
    else
      File.join(shared.export_path, Gitlab::ImportExport.project_filename)
    end
  end

  let(:exportable_path) { 'project' }

  before do
    stub_feature_flags(project_export_as_ndjson: ndjson_enabled)
  end

  it 'saves successfully' do
    expect(project_tree_saver.save).to be true
  end

  describe 'the designs json' do
    let(:issue_json) { saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first }

    it 'saves issue.designs correctly' do
      expect(issue_json['designs'].size).to eq(1)
    end

    it 'saves issue.design_versions correctly' do
      actions = issue_json['design_versions'].flat_map { |v| v['actions'] }

      expect(issue_json['design_versions'].size).to eq(2)
      issue_json['design_versions'].each do |version|
        expect(version['author_id']).to eq(issue.author_id)
      end
      expect(actions.size).to eq(2)
      actions.each do |action|
        expect(action['design']).to be_present
      end
    end
  end

  context 'epics' do
    it 'has epic_issue' do
      expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['epic_issue']).not_to be_empty
      expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['epic_issue']['id']).to eql(epic_issue.id)
    end

    it 'has epic' do
      expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['epic_issue']['epic']['title']).to eql(epic.title)
    end

    it 'does not have epic_id' do
      expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['epic_issue']['epic_id']).to be_nil
    end

    it 'does not have issue_id' do
      expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['epic_issue']['issue_id']).to be_nil
    end
  end
end
