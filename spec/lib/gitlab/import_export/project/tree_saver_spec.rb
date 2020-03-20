# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Project::TreeSaver do
  let(:shared) { project.import_export_shared }
  let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:user) { create(:user) }
  let!(:project) { setup_project }

  before do
    project.add_maintainer(user)
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    allow_any_instance_of(MergeRequest).to receive(:source_branch_sha).and_return('ABCD')
    allow_any_instance_of(MergeRequest).to receive(:target_branch_sha).and_return('DCBA')
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  context 'with JSON' do
    it_behaves_like "saves project tree successfully", false
  end

  context 'with NDJSON' do
    it_behaves_like "saves project tree successfully", true
  end

  def setup_project
    release = create(:release)
    group = create(:group)

    project = create(:project,
                     :public,
                     :repository,
                     :issues_disabled,
                     :wiki_enabled,
                     :builds_private,
                     description: 'description',
                     releases: [release],
                     group: group,
                     approvals_before_merge: 1
                    )
    allow(project).to receive(:commit).and_return(Commit.new(RepoHelpers.sample_commit, project))

    issue = create(:issue, assignees: [user], project: project)
    snippet = create(:project_snippet, project: project)
    project_label = create(:label, project: project)
    group_label = create(:group_label, group: group)
    create(:label_link, label: project_label, target: issue)
    create(:label_link, label: group_label, target: issue)
    create(:label_priority, label: group_label, priority: 1)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone)

    ci_build = create(:ci_build, project: project, when: nil)
    ci_build.pipeline.update(project: project)
    create(:commit_status, project: project, pipeline: ci_build.pipeline)

    create(:milestone, project: project)
    discussion_note = create(:discussion_note, noteable: issue, project: project)
    mr_note = create(:note, noteable: merge_request, project: project)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
           author: user,
           project: project,
           commit_id: ci_build.pipeline.sha)

    create(:system_note_metadata, action: 'description', note: discussion_note)
    create(:system_note_metadata, commit_count: 1, action: 'commit', note: mr_note)

    create(:resource_label_event, label: project_label, issue: issue)
    create(:resource_label_event, label: group_label, merge_request: merge_request)

    create(:event, :created, target: milestone, project: project, author: user)
    create(:service, project: project, type: 'CustomIssueTrackerService', category: 'issue_tracker', properties: { one: 'value' })

    create(:project_custom_attribute, project: project)
    create(:project_custom_attribute, project: project)

    create(:project_badge, project: project)
    create(:project_badge, project: project)

    board = create(:board, project: project, name: 'TestBoard')
    create(:list, board: board, position: 0, label: project_label)

    project
  end
end
