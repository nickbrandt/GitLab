# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Project::TreeSaver do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let_it_be(:design) { create(:design, :with_file, versions_count: 2, issue: issue) }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, project: project, author: user) }
  let_it_be(:note2) { create(:note, noteable: issue, project: project, author: user) }

  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic_issue) { create(:epic_issue, issue: issue, epic: epic) }

  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec_ee" }
  let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }

  before do
    project.add_maintainer(user)
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  context 'with JSON' do
    it_behaves_like "EE saves project tree successfully", false
  end

  context 'with NDJSON' do
    it_behaves_like "EE saves project tree successfully", true
  end
end
