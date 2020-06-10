# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, :wiki_repo, name: 'awesome project', group: group) }

  before_all do
    login_as(user)
  end

  def send_search_request(params)
    get search_path, params: params
  end

  describe 'GET /search' do
    context 'when elasticsearch is enabled', :elastic, :sidekiq_inline do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      end

      context 'for merge_request scope' do
        before do
          create(:merge_request, target_branch: 'feature_1', source_project: project)
          create(:merge_request, target_branch: 'feature_2', source_project: project)
          create(:merge_request, target_branch: 'feature_3', source_project: project)
          create(:merge_request, target_branch: 'feature_4', source_project: project)
          ensure_elasticsearch_index!
        end

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_search_request(scope: 'merge_requests', search: '*') }

          create(:merge_request, target_branch: 'feature_5', source_project: project)
          create(:merge_request, target_branch: 'feature_6', source_project: project)
          create(:merge_request, target_branch: 'feature_7', source_project: project)
          create(:merge_request, target_branch: 'feature_8', source_project: project)

          ensure_elasticsearch_index!

          # some N+1 queries still exist
          expect { send_search_request(scope: 'merge_requests', search: '*') }
            .not_to exceed_all_query_limit(control)
        end
      end

      context 'for project scope' do
        before do
          create(:project, :public)
          ensure_elasticsearch_index!
        end

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_search_request(scope: 'project', search: '*') }

          create_list(:project, 3, :public)

          ensure_elasticsearch_index!

          # some N+1 queries still exist
          # each project requires 3 extra queries
          #   - one count for forks
          #   - one count for open MRs
          #   - one count for open Issues
          expect { send_search_request(scope: 'project', search: '*') }
            .not_to exceed_all_query_limit(control).with_threshold(9)
        end
      end
    end
  end
end
