# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeSaver do
  describe 'saves the project tree into a json object' do
    set(:user) { create(:user) }
    set(:project) { create(:project) }
    set(:issue) { create(:issue, project: project) }
    set(:design) { create(:design, :with_file, versions_count: 2, issue: issue) }
    set(:note) { create(:diff_note_on_design, noteable: design, project: project, author: user) }
    set(:note2) { create(:note, noteable: issue, project: project, author: user) }
    let(:shared) { project.import_export_shared }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec_ee" }
    let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }
    let(:saved_project_json) do
      project_tree_saver.save
      project_json(project_tree_saver.full_path)
    end

    before do
      project.add_maintainer(user)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves successfully' do
      expect(project_tree_saver.save).to be true
    end

    describe 'the designs json' do
      let(:issue_json) { saved_project_json['issues'].first }

      it 'saves issue.designs correctly' do
        expect(issue_json['designs'].size).to eq(1)
      end

      it 'saves issue.design_versions correctly' do
        actions = issue_json['design_versions'].map do |v|
          v['actions']
        end.flatten

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
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end
end
