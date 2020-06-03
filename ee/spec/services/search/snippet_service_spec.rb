# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::SnippetService do
  include SearchResultHelpers
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'EE search service shared examples', ::Gitlab::SnippetSearchResults, ::Gitlab::Elastic::SnippetSearchResults do
    let(:user) { create(:user) }
    let(:scope) { nil }
    let(:service) { described_class.new(user, params) }
  end

  describe '#execute', :elastic, :sidekiq_inline do
    include_context 'ProjectPolicyTable context'

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    context 'visibility' do
      include_context 'ProjectPolicyTable context'
      include ProjectHelpers

      let(:search_term) { 'foobar' }

      context 'project snippet' do
        let(:pendings) do
          [
            { snippet_level: :public, project_level: :public, feature_access_level: :enabled, membership: :non_member, expected_count: 1 },
            { snippet_level: :public, project_level: :internal, feature_access_level: :enabled, membership: :non_member, expected_count: 1 },
            { snippet_level: :internal, project_level: :public, feature_access_level: :enabled, membership: :non_member, expected_count: 1 },
            { snippet_level: :internal, project_level: :internal, feature_access_level: :enabled, membership: :non_member, expected_count: 1 }
          ]
        end
        let(:pending?) do
          pendings.include?(
            {
              snippet_level: snippet_level,
              project_level: project_level,
              feature_access_level: feature_access_level,
              membership: membership,
              expected_count: expected_count
            }
          )
        end

        let_it_be(:group) { create(:group) }
        let!(:project) { create(:project, project_level, namespace: group) }
        let!(:snippet) { create(:project_snippet, snippet_level, project: project, title: search_term, content: search_term) }
        let(:user) { create_user_from_membership(project, membership) }

        where(:snippet_level, :project_level, :feature_access_level, :membership, :expected_count) do
          permission_table_for_project_snippet_access
        end

        with_them do
          it "respects visibility" do
            update_feature_access_level(project, feature_access_level)
            ensure_elasticsearch_index!

            expected_objects = expected_count == 0 ? [] : [snippet]

            expect_search_results(user, 'snippet_titles', expected_objects: expected_objects, pending: pending?) do |user|
              described_class.new(user, search: search_term).execute
            end

            expect_search_results(user, 'snippet_blobs', expected_objects: expected_objects, pending: pending?) do |user|
              described_class.new(user, search: search_term).execute
            end
          end
        end
      end

      context 'personal snippet' do
        let(:user) do
          if membership == :author
            snippet.author
          else
            create_user_from_membership(nil, membership)
          end
        end
        let!(:snippet) { create(:personal_snippet, snippet_level, title: search_term, content: search_term) }

        where(:snippet_level, :membership, :expected_count) do
          permission_table_for_personal_snippet_access
        end

        with_them do
          it "respects visibility" do
            ensure_elasticsearch_index!
            expected_objects = expected_count == 0 ? [] : [snippet]

            expect_search_results(user, 'snippet_titles', expected_objects: expected_objects) do |user|
              described_class.new(user, search: search_term).execute
            end

            expect_search_results(user, 'snippet_blobs', expected_objects: expected_objects) do |user|
              described_class.new(user, search: search_term).execute
            end
          end
        end
      end
    end
  end
end
