# frozen_string_literal: true

require 'spec_helper'

describe Search::GlobalService do
  include SearchResultHelpers
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it_behaves_like 'EE search service shared examples', ::Gitlab::SearchResults, ::Gitlab::Elastic::SearchResults do
    let(:scope) { nil }
    let(:service) { described_class.new(user, params) }
  end

  context 'visibility', :elastic, :sidekiq_inline do
    include_context 'ProjectPolicyTable context'

    set(:group) { create(:group) }
    let(:project) { create(:project, project_level, namespace: group) }
    let(:user) { create_user_from_membership(project, membership) }

    context 'merge request' do
      let!(:merge_request) { create :merge_request, target_project: project, source_project: project }
      let!(:note) { create :note, project: project, noteable: merge_request }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it "respects visibility" do
          update_feature_access_level(project, feature_access_level)
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'merge_requests', expected_count: expected_count, pending: pending?) do |user|
            described_class.new(user, search: merge_request.title).execute
          end

          expect_search_results(user, 'notes', expected_count: expected_count) do |user|
            described_class.new(user, search: note.note).execute
          end
        end
      end
    end

    context 'code' do
      let!(:project) { create(:project, project_level, :repository, namespace: group ) }
      let!(:note) { create :note_on_commit, project: project }
      let(:pendings) do
        [
          { project_level: :public, feature_access_level: :private, membership: :guest, expected_count: 1 },
          { project_level: :internal, feature_access_level: :private, membership: :guest, expected_count: 1 }
        ]
      end

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_guest_feature_access_and_non_private_project_only
      end

      with_them do
        it "respects visibility" do
          update_feature_access_level(project, feature_access_level)
          ElasticCommitIndexerWorker.new.perform(project.id)
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'commits', expected_count: expected_count, pending: pending?) do |user|
            described_class.new(user, search: 'initial').execute
          end

          expect_search_results(user, 'blobs', expected_count: expected_count) do |user|
            described_class.new(user, search: '.gitmodules').execute
          end

          expect_search_results(user, 'notes', expected_count: expected_count) do |user|
            described_class.new(user, search: note.note).execute
          end
        end
      end
    end

    context 'issue' do
      let!(:issue) { create :issue, project: project }
      let!(:note) { create :note, project: project, noteable: issue }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          update_feature_access_level(project, feature_access_level)
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'issues', expected_count: expected_count) do |user|
            described_class.new(user, search: issue.title).execute
          end

          expect_search_results(user, 'notes', expected_count: expected_count) do |user|
            described_class.new(user, search: note.note).execute
          end
        end
      end
    end

    context 'wiki' do
      let!(:project) { create(:project, project_level, :wiki_repo) }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          project.wiki.create_page('test.md', '# term')
          project.wiki.index_wiki_blobs
          update_feature_access_level(project, feature_access_level)
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'wiki_blobs', expected_count: expected_count) do |user|
            described_class.new(user, search: 'term').execute
          end
        end
      end
    end

    context 'milestone' do
      let!(:milestone) { create :milestone, project: project }

      where(:project_level, :issues_access_level, :merge_requests_access_level, :membership, :expected_count) do
        permission_table_for_milestone_access
      end

      with_them do
        it "respects visibility" do
          project.update!(
            'issues_access_level' => issues_access_level,
            'merge_requests_access_level' => merge_requests_access_level
          )
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'milestones', expected_count: expected_count) do |user|
            described_class.new(user, search: milestone.title).execute
          end
        end
      end
    end

    context 'project' do
      where(:project_level, :membership, :expected_count) do
        permission_table_for_project_access
      end

      with_them do
        it "respects visibility" do
          ElasticCommitIndexerWorker.new.perform(project.id)
          Gitlab::Elastic::Helper.refresh_index

          expected_objects = expected_count == 1 ? [project] : []

          expect_search_results(
            user,
            'projects',
            expected_count: expected_count,
            expected_objects: expected_objects
          ) do |user|
            described_class.new(user, search: project.name).execute
          end
        end
      end
    end
  end
end
