# frozen_string_literal: true

require 'spec_helper'

describe API::Search do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  let(:project) { create(:project, :public, :wiki_repo, name: 'awesome project', group: group) }
  let(:repo_project) { create(:project, :public, :repository, group: group) }

  shared_examples 'response is correct' do |schema:, size: 1|
    it { expect(response).to have_gitlab_http_status(200) }
    it { expect(response).to match_response_schema(schema) }
    it { expect(response).to include_limited_pagination_headers }
    it { expect(json_response.size).to eq(size) }
  end

  shared_examples 'elasticsearch disabled' do
    it 'returns 400 error for wiki_blobs scope' do
      get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error for blobs scope' do
      get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }

      expect(response).to have_gitlab_http_status(400)
    end

    it 'returns 400 error for commits scope' do
      get api(endpoint, user), params: { scope: 'commits', search: 'folder' }

      expect(response).to have_gitlab_http_status(400)
    end
  end

  shared_examples 'elasticsearch enabled' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    context 'for wiki_blobs scope', :sidekiq_might_not_need_inline do
      before do
        wiki = create(:project_wiki, project: project)
        create(:wiki_page, wiki: wiki, attrs: { title: 'home', content: "Awesome page" })

        project.wiki.index_wiki_blobs
        Gitlab::Elastic::Helper.refresh_index

        get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }
      end

      it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'
    end

    context 'for commits scope', :sidekiq_might_not_need_inline do
      before do
        repo_project.repository.index_commits_and_blobs
        Gitlab::Elastic::Helper.refresh_index

        get api(endpoint, user), params: { scope: 'commits', search: 'folder' }
      end

      it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details', size: 2
    end

    context 'for blobs scope', :sidekiq_might_not_need_inline do
      before do
        repo_project.repository.index_commits_and_blobs
        Gitlab::Elastic::Helper.refresh_index

        get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }
      end

      it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'

      context 'filters' do
        it 'by filename' do
          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon filename:PROCESS.md' }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(1)
          expect(json_response.first['path']).to eq('PROCESS.md')
        end

        it 'by path' do
          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon path:markdown' }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(1)
          json_response.each do |file|
            expect(file['path']).to match(%r[/markdown/])
          end
        end

        it 'by extension' do
          get api("/projects/#{repo_project.id}/search", user), params: { scope: 'blobs', search: 'mon extension:md' }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.size).to eq(3)
          json_response.each do |file|
            expect(file['path']).to match(/\A.+\.md\z/)
          end
        end
      end
    end
  end

  describe 'GET /search' do
    context 'with correct params' do
      context 'when elasticsearch is disabled' do
        it_behaves_like 'elasticsearch disabled' do
          let(:endpoint) { '/search' }
        end
      end

      context 'when elasticsearch is enabled', :elastic do
        it_behaves_like 'elasticsearch enabled' do
          let(:endpoint) { '/search' }
        end
      end
    end
  end

  describe "GET /groups/:id/-/search" do
    context 'with correct params' do
      context 'when elasticsearch is disabled' do
        it_behaves_like 'elasticsearch disabled' do
          let(:endpoint) { "/groups/#{group.id}/-/search" }
        end
      end

      context 'when elasticsearch is enabled', :elastic do
        it_behaves_like 'elasticsearch enabled' do
          let(:endpoint) { "/groups/#{group.id}/-/search" }
        end
      end
    end
  end
end
