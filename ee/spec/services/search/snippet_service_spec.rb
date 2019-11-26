# frozen_string_literal: true

require 'spec_helper'

describe Search::SnippetService do
  include SearchResultHelpers
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'EE search service shared examples', ::Gitlab::SnippetSearchResults, ::Gitlab::Elastic::SnippetSearchResults do
    let(:user) { create(:user) }
    let(:scope) { nil }
    let(:service) { described_class.new(user, search: '*') }
  end

  describe '#execute', :elastic, :sidekiq_inline do
    include_context 'ProjectPolicyTable context'

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    context 'visibility' do
      let(:search_term) { 'foobar' }

      context 'project snippet' do
        let_it_be(:group) { create(:group) }
        let!(:project) { create(:project, project_level, namespace: group) }
        let!(:snippet) { create(:project_snippet, snippet_level, project: project, title: search_term, content: search_term) }
        let(:user) { create_user_from_membership(project, membership) }

        where(:snippet_level, :project_level, :feature_access_level, :membership, :expected_count) do
          :public   | :public   | :enabled  | :admin      | 1
          :public   | :public   | :enabled  | :reporter   | 1
          :public   | :public   | :enabled  | :guest      | 1
          :public   | :public   | :enabled  | :non_member | 1
          :public   | :public   | :enabled  | :anonymous  | 1

          :public   | :public   | :private  | :admin      | 1
          :public   | :public   | :private  | :reporter   | 1
          :public   | :public   | :private  | :guest      | 1
          :public   | :public   | :private  | :non_member | 0
          :public   | :public   | :private  | :anonymous  | 0

          :public   | :public   | :disabled | :admin      | 1
          :public   | :public   | :disabled | :reporter   | 0
          :public   | :public   | :disabled | :guest      | 0
          :public   | :public   | :disabled | :non_member | 0
          :public   | :public   | :disabled | :anonymous  | 0

          :public   | :internal | :enabled  | :admin      | 1
          :public   | :internal | :enabled  | :reporter   | 1
          :public   | :internal | :enabled  | :guest      | 1
          :public   | :internal | :enabled  | :non_member | 1
          :public   | :internal | :enabled  | :anonymous  | 0

          :public   | :internal | :private  | :admin      | 1
          :public   | :internal | :private  | :reporter   | 1
          :public   | :internal | :private  | :guest      | 1
          :public   | :internal | :private  | :non_member | 0
          :public   | :internal | :private  | :anonymous  | 0

          :public   | :internal | :disabled | :admin      | 1
          :public   | :internal | :disabled | :reporter   | 0
          :public   | :internal | :disabled | :guest      | 0
          :public   | :internal | :disabled | :non_member | 0
          :public   | :internal | :disabled | :anonymous  | 0

          :public   | :private  | :private  | :admin      | 1
          :public   | :private  | :private  | :reporter   | 1
          :public   | :private  | :private  | :guest      | 1
          :public   | :private  | :private  | :non_member | 0
          :public   | :private  | :private  | :anonymous  | 0

          :public   | :private  | :disabled | :reporter   | 0
          :public   | :private  | :disabled | :guest      | 0
          :public   | :private  | :disabled | :non_member | 0
          :public   | :private  | :disabled | :anonymous  | 0

          :internal | :public   | :enabled  | :admin      | 1
          :internal | :public   | :enabled  | :reporter   | 1
          :internal | :public   | :enabled  | :guest      | 1
          :internal | :public   | :enabled  | :non_member | 1
          :internal | :public   | :enabled  | :anonymous  | 0

          :internal | :public   | :private  | :admin      | 1
          :internal | :public   | :private  | :reporter   | 1
          :internal | :public   | :private  | :guest      | 1
          :internal | :public   | :private  | :non_member | 0
          :internal | :public   | :private  | :anonymous  | 0

          :internal | :public   | :disabled | :admin      | 1
          :internal | :public   | :disabled | :reporter   | 0
          :internal | :public   | :disabled | :guest      | 0
          :internal | :public   | :disabled | :non_member | 0
          :internal | :public   | :disabled | :anonymous  | 0

          :internal | :internal | :enabled  | :admin      | 1
          :internal | :internal | :enabled  | :reporter   | 1
          :internal | :internal | :enabled  | :guest      | 1
          :internal | :internal | :enabled  | :non_member | 1
          :internal | :internal | :enabled  | :anonymous  | 0

          :internal | :internal | :private  | :admin      | 1
          :internal | :internal | :private  | :reporter   | 1
          :internal | :internal | :private  | :guest      | 1
          :internal | :internal | :private  | :non_member | 0
          :internal | :internal | :private  | :anonymous  | 0

          :internal | :internal | :disabled | :admin      | 1
          :internal | :internal | :disabled | :reporter   | 0
          :internal | :internal | :disabled | :guest      | 0
          :internal | :internal | :disabled | :non_member | 0
          :internal | :internal | :disabled | :anonymous  | 0

          :internal | :private  | :private  | :admin      | 1
          :internal | :private  | :private  | :reporter   | 1
          :internal | :private  | :private  | :guest      | 1
          :internal | :private  | :private  | :non_member | 0
          :internal | :private  | :private  | :anonymous  | 0

          :internal | :private  | :disabled | :admin      | 1
          :internal | :private  | :disabled | :reporter   | 0
          :internal | :private  | :disabled | :guest      | 0
          :internal | :private  | :disabled | :non_member | 0
          :internal | :private  | :disabled | :anonymous  | 0

          :private  | :public   | :enabled  | :admin      | 1
          :private  | :public   | :enabled  | :reporter   | 1
          :private  | :public   | :enabled  | :guest      | 1
          :private  | :public   | :enabled  | :non_member | 0
          :private  | :public   | :enabled  | :anonymous  | 0

          :private  | :public   | :private  | :admin      | 1
          :private  | :public   | :private  | :reporter   | 1
          :private  | :public   | :private  | :guest      | 1
          :private  | :public   | :private  | :non_member | 0
          :private  | :public   | :private  | :anonymous  | 0

          :private  | :public   | :disabled | :admin      | 1
          :private  | :public   | :disabled | :reporter   | 0
          :private  | :public   | :disabled | :guest      | 0
          :private  | :public   | :disabled | :non_member | 0
          :private  | :public   | :disabled | :anonymous  | 0

          :private  | :internal | :enabled  | :admin      | 1
          :private  | :internal | :enabled  | :reporter   | 1
          :private  | :internal | :enabled  | :guest      | 1
          :private  | :internal | :enabled  | :non_member | 0
          :private  | :internal | :enabled  | :anonymous  | 0

          :private  | :internal | :private  | :admin      | 1
          :private  | :internal | :private  | :reporter   | 1
          :private  | :internal | :private  | :guest      | 1
          :private  | :internal | :private  | :non_member | 0
          :private  | :internal | :private  | :anonymous  | 0

          :private  | :internal | :disabled | :admin      | 1
          :private  | :internal | :disabled | :reporter   | 0
          :private  | :internal | :disabled | :guest      | 0
          :private  | :internal | :disabled | :non_member | 0
          :private  | :internal | :disabled | :anonymous  | 0

          :private  | :private  | :private  | :admin      | 1
          :private  | :private  | :private  | :reporter   | 1
          :private  | :private  | :private  | :guest      | 1
          :private  | :private  | :private  | :non_member | 0
          :private  | :private  | :private  | :anonymous  | 0

          :private  | :private  | :disabled | :admin      | 1
          :private  | :private  | :disabled | :reporter   | 0
          :private  | :private  | :disabled | :guest      | 0
          :private  | :private  | :disabled | :non_member | 0
          :private  | :private  | :disabled | :anonymous  | 0
        end

        with_them do
          it "respects visibility" do
            update_feature_access_level(project, feature_access_level)
            Gitlab::Elastic::Helper.refresh_index

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
          :public   | :admin      | 1
          :public   | :author     | 1
          :public   | :non_member | 1
          :public   | :anonymous  | 1

          :internal | :admin      | 1
          :internal | :author     | 1
          :internal | :non_member | 1
          :internal | :anonymous  | 0

          :private  | :admin      | 1
          :private  | :author     | 1
          :private  | :non_member | 0
          :private  | :anonymous  | 0
        end

        with_them do
          it "respects visibility" do
            Gitlab::Elastic::Helper.refresh_index
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
