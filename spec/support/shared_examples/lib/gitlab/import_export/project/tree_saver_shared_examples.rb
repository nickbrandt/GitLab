# frozen_string_literal: true

RSpec.shared_examples 'saves project tree successfully' do |ndjson_enabled|
  include ImportExport::CommonUtil

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

  it 'saves project successfully' do
    expect(project_tree_saver.save).to be true
  end
  # It is not duplicated indoes not contain the runners token
  # `spec/lib/gitlab/import_export/fast_hash_serializer_spec.rb`
  context 'with description override' do
    let(:params) { { description: 'Foo Bar' } }
    let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared, params: params) }

    it 'overrides the project description' do
      expect(saved_relations(full_path, exportable_path, :projects, ndjson_enabled)).to include({ 'description' => params[:description] })
    end
  end

  it 'saves the correct json' do
    expect(saved_relations(full_path, exportable_path, :projects, ndjson_enabled)).to include({ 'description' => 'description', 'visibility_level' => 20 })
  end

  it 'has approvals_before_merge set' do
    expect(saved_relations(full_path, exportable_path, :projects, ndjson_enabled)['approvals_before_merge']).to eq(1)
  end

  it 'has milestones' do
    expect(saved_relations(full_path, exportable_path, :milestones, ndjson_enabled)).not_to be_empty
  end

  it 'has merge requests' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled)).not_to be_empty
  end

  it 'has merge request\'s milestones' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['milestone']).not_to be_empty
  end
  it 'has merge request\'s source branch SHA' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['source_branch_sha']).to eq('ABCD')
  end

  it 'has merge request\'s target branch SHA' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['target_branch_sha']).to eq('DCBA')
  end

  it 'has events' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['milestone']['events']).not_to be_empty
  end

  it 'has snippets' do
    expect(saved_relations(full_path, exportable_path, :snippets, ndjson_enabled)).not_to be_empty
  end

  it 'has snippet notes' do
    expect(saved_relations(full_path, exportable_path, :snippets, ndjson_enabled).first['notes']).not_to be_empty
  end

  it 'has releases' do
    expect(saved_relations(full_path, exportable_path, :releases, ndjson_enabled)).not_to be_empty
  end

  it 'has no author on releases' do
    expect(saved_relations(full_path, exportable_path, :releases, ndjson_enabled).first['author']).to be_nil
  end

  it 'has the author ID on releases' do
    expect(saved_relations(full_path, exportable_path, :releases, ndjson_enabled).first['author_id']).not_to be_nil
  end

  it 'has issues' do
    expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled)).not_to be_empty
  end

  it 'has issue comments' do
    notes = saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['notes']

    expect(notes).not_to be_empty
    expect(notes.first['type']).to eq('DiscussionNote')
  end

  it 'has issue assignees' do
    expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['issue_assignees']).not_to be_empty
  end

  it 'has author on issue comments' do
    expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['notes'].first['author']).not_to be_empty
  end

  it 'has project members' do
    expect(saved_relations(full_path, exportable_path, :project_members, ndjson_enabled)).not_to be_empty
  end

  it 'has merge requests diffs' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['merge_request_diff']).not_to be_empty
  end

  it 'has merge request diff files' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['merge_request_diff']['merge_request_diff_files']).not_to be_empty
  end

  it 'has merge request diff commits' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['merge_request_diff']['merge_request_diff_commits']).not_to be_empty
  end

  it 'has merge requests comments' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['notes']).not_to be_empty
  end

  it 'has author on merge requests comments' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['notes'].first['author']).not_to be_empty
  end

  it 'has pipeline stages' do
    expect(saved_relations(full_path, exportable_path, :ci_pipelines, ndjson_enabled).dig(0, 'stages')).not_to be_empty
  end

  it 'has pipeline statuses' do
    expect(saved_relations(full_path, exportable_path, :ci_pipelines, ndjson_enabled).dig(0, 'stages', 0, 'statuses')).not_to be_empty
  end

  it 'has pipeline builds' do
    builds_count = saved_relations(full_path, exportable_path, :ci_pipelines, ndjson_enabled).dig(0, 'stages', 0, 'statuses')
      .count { |hash| hash['type'] == 'Ci::Build' }

    expect(builds_count).to eq(1)
  end

  it 'has no when YML attributes but only the DB column' do
    expect_any_instance_of(Gitlab::Ci::YamlProcessor).not_to receive(:build_attributes)

    project_tree_saver.save
  end

  it 'has pipeline commits' do
    expect(saved_relations(full_path, exportable_path, :ci_pipelines, ndjson_enabled)).not_to be_empty
  end

  it 'has ci pipeline notes' do
    expect(saved_relations(full_path, exportable_path, :ci_pipelines, ndjson_enabled).first['notes']).not_to be_empty
  end

  it 'has labels with no associations' do
    expect(saved_relations(full_path, exportable_path, :labels, ndjson_enabled)).not_to be_empty
  end

  it 'has labels associated to records' do
    expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['label_links'].first['label']).not_to be_empty
  end

  it 'has project and group labels' do
    label_types = saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['label_links'].map { |link| link['label']['type'] }

    expect(label_types).to match_array(%w(ProjectLabel GroupLabel))
  end

  it 'has priorities associated to labels' do
    priorities = saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['label_links'].flat_map { |link| link['label']['priorities'] }

    expect(priorities).not_to be_empty
  end

  it 'has issue resource label events' do
    expect(saved_relations(full_path, exportable_path, :issues, ndjson_enabled).first['resource_label_events']).not_to be_empty
  end

  it 'has merge request resource label events' do
    expect(saved_relations(full_path, exportable_path, :merge_requests, ndjson_enabled).first['resource_label_events']).not_to be_empty
  end

  it 'saves the correct service type' do
    expect(saved_relations(full_path, exportable_path, :services, ndjson_enabled).first['type']).to eq('CustomIssueTrackerService')
  end

  it 'saves the properties for a service' do
    expect(saved_relations(full_path, exportable_path, :services, ndjson_enabled).first['properties']).to eq('one' => 'value')
  end

  it 'has project feature' do
    project_feature = saved_relations(full_path, exportable_path, :project_feature, ndjson_enabled)
    expect(project_feature).not_to be_empty
    expect(project_feature["issues_access_level"]).to eq(ProjectFeature::DISABLED)
    expect(project_feature["wiki_access_level"]).to eq(ProjectFeature::ENABLED)
    expect(project_feature["builds_access_level"]).to eq(ProjectFeature::PRIVATE)
  end

  it 'has custom attributes' do
    expect(saved_relations(full_path, exportable_path, :custom_attributes, ndjson_enabled).count).to eq(2)
  end

  it 'has badges' do
    expect(saved_relations(full_path, exportable_path, :project_badges, ndjson_enabled).count).to eq(2)
  end

  it 'does not complain about non UTF-8 characters in MR diff files' do
    ActiveRecord::Base.connection.execute("UPDATE merge_request_diff_files SET diff = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

    expect(project_tree_saver.save).to be true
  end

  context 'group members' do
    let(:user2) { create(:user, email: 'group@member.com') }
    let(:member_emails) do
      emails = saved_relations(full_path, exportable_path, :project_members, ndjson_enabled).map do |pm|
        pm['user']['email']
      end
      emails
    end

    before do
      Group.first.add_developer(user2)
    end

    it 'does not export group members if it has no permission' do
      Group.first.add_developer(user)

      expect(member_emails).not_to include('group@member.com')
    end

    it 'does not export group members as maintainer' do
      Group.first.add_maintainer(user)

      expect(member_emails).not_to include('group@member.com')
    end

    it 'exports group members as group owner' do
      Group.first.add_owner(user)

      expect(member_emails).to include('group@member.com')
    end

    context 'as admin' do
      let(:user) { create(:admin) }

      it 'exports group members as admin' do
        expect(member_emails).to include('group@member.com')
      end

      it 'exports group members as project members' do
        member_types = saved_relations(full_path, exportable_path, :project_members, ndjson_enabled).map { |pm| pm['source_type'] }

        expect(member_types).to all(eq('Project'))
      end
    end
  end

  context 'project attributes' do
    it 'does not contain the runners token' do
      expect(saved_relations(full_path, exportable_path, :projects, ndjson_enabled)).not_to include("runners_token" => 'token')
    end
  end

  it 'has a board and a list' do
    expect(saved_relations(full_path, exportable_path, :boards, ndjson_enabled).first['lists']).not_to be_empty
  end
end
