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
    let(:service) { described_class.new(user, search: '*') }
  end

  context 'visibility', :elastic do
    include_context 'ProjectPolicyTable context'

    set(:group) { create(:group) }
    let(:project) { create(:project, project_level, namespace: group) }
    let(:project2) { create(:project, project_level) }
    let(:user) { create_user_from_membership(project, membership) }

    context 'merge request' do
      let!(:merge_request) { create :merge_request, target_project: project, source_project: project }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it "respects visibility" do
          [project, project2].each do |project|
            update_feature_access_level(project, feature_access_level)
          end
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'merge_requests', expected_count: expected_count) do |user|
            described_class.new(user, search: merge_request.title).execute
          end
        end
      end
    end

    context 'code' do
      let!(:project) { create(:project, project_level, :repository, namespace: group ) }
      let!(:project2) { create(:project, project_level, :repository) }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          [project, project2].each do |project|
            update_feature_access_level(project, feature_access_level)
            ElasticCommitIndexerWorker.new.perform(project.id)
          end
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'commits', expected_count: expected_count) do |user|
            described_class.new(user, search: 'initial').execute
          end

          expect_search_results(user, 'blobs', expected_count: expected_count) do |user|
            described_class.new(user, search: '.gitmodules').execute
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
