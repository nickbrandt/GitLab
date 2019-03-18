# frozen_string_literal: true

require 'spec_helper'

describe SnippetsHelper do
  include Gitlab::Routing
  include IconsHelper

  let_it_be(:public_personal_snippet) { create(:personal_snippet, :public) }
  let_it_be(:secret_snippet) { create(:personal_snippet, :secret) }
  let_it_be(:public_project_snippet) { create(:project_snippet, :public) }

  describe '.reliable_snippet_path' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full path' do
          expect(reliable_snippet_path(public_personal_snippet)).to eq("/snippets/#{public_personal_snippet.id}")
        end
      end

      context 'secret' do
        it 'gives a full path, including secret word' do
          expect(reliable_snippet_path(secret_snippet)).to match(%r{/snippets/#{secret_snippet.id}\?token=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full path' do
        expect(reliable_snippet_path(public_project_snippet)).to eq("/#{public_project_snippet.project.full_path}/snippets/#{public_project_snippet.id}")
      end
    end
  end

  describe '.reliable_snippet_url' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full url' do
          expect(reliable_snippet_url(public_personal_snippet)).to eq("http://test.host/snippets/#{public_personal_snippet.id}")
        end
      end

      context 'secret' do
        it 'gives a full url, including secret word' do
          expect(reliable_snippet_url(secret_snippet)).to match(%r{http://test.host/snippets/#{secret_snippet.id}\?token=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full url' do
        expect(reliable_snippet_url(public_project_snippet)).to eq("http://test.host/#{public_project_snippet.project.full_path}/snippets/#{public_project_snippet.id}")
      end
    end
  end

  describe '.shareable_snippets_link' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full link' do
          expect(reliable_snippet_url(public_personal_snippet)).to eq("http://test.host/snippets/#{public_personal_snippet.id}")
        end
      end

      context 'secret' do
        it 'gives a full link, including secret word' do
          expect(reliable_snippet_url(secret_snippet)).to match(%r{http://test.host/snippets/#{secret_snippet.id}\?token=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full link' do
        expect(reliable_snippet_url(public_project_snippet)).to eq("http://test.host/#{public_project_snippet.project.full_path}/snippets/#{public_project_snippet.id}")
      end
    end
  end

  describe '.embedded_snippet_raw_button' do
    it 'gives view raw button of embedded snippets for project snippets' do
      @snippet = public_project_snippet

      expect(embedded_snippet_raw_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{raw_project_snippet_url(@snippet.project, @snippet)}\">#{external_snippet_icon('doc-code')}</a>")
    end

    it 'gives view raw button of embedded snippets for personal snippets' do
      @snippet = public_personal_snippet

      expect(embedded_snippet_raw_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{raw_snippet_url(@snippet)}\">#{external_snippet_icon('doc-code')}</a>")
    end
  end

  describe '.embedded_snippet_download_button' do
    it 'gives download button of embedded snippets for project snippets' do
      @snippet = public_project_snippet

      expect(embedded_snippet_download_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{raw_project_snippet_url(@snippet.project, @snippet, inline: false)}\">#{external_snippet_icon('download')}</a>")
    end

    it 'gives download button of embedded snippets for personal snippets' do
      @snippet = public_personal_snippet

      expect(embedded_snippet_download_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{raw_snippet_url(@snippet, inline: false)}\">#{external_snippet_icon('download')}</a>")
    end
  end

  describe '.snippet_embed_url' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full link' do
          expect(snippet_embed_url(public_personal_snippet)).to eq("<script src=\"http://test.host/snippets/#{public_personal_snippet.id}.js\"></script>")
        end
      end

      context 'secret' do
        it 'gives a full link, including secret word' do
          expect(snippet_embed_url(secret_snippet)).to eq("<script src=\"http://test.host/snippets/#{secret_snippet.id}.js?token=#{secret_snippet.secret_token}\"></script>")
        end
      end
    end

    context 'project snippets' do
      it 'gives a full link' do
        expect(snippet_embed_url(public_project_snippet)).to eq("<script src=\"http://test.host/#{public_project_snippet.project.full_path}/snippets/#{public_project_snippet.id}.js\"></script>")
      end
    end
  end
end
