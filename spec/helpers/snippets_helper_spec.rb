# frozen_string_literal: true

require 'spec_helper'

describe SnippetsHelper do
  include IconsHelper

  let_it_be(:public_personal_snippet) { create(:personal_snippet, :public) }
  let_it_be(:secret_snippet) { create(:personal_snippet, :secret) }
  let_it_be(:public_project_snippet) { create(:project_snippet, :public) }
  let(:current_user) { nil }

  describe '#embedded_raw_snippet_button' do
    subject { embedded_raw_snippet_button.to_s }

    it 'returns view raw button of embedded snippets for personal snippets' do
      @snippet = create(:personal_snippet, :public)
      expect(subject).to eq(download_link("http://test.host/snippets/#{@snippet.id}/raw"))
    end

    it 'returns raw button of embedded snippets for secret personal snippets' do
      @snippet = create(:personal_snippet, :secret)

      expect(subject).to eq(download_link("http://test.host/snippets/#{@snippet.id}/raw?token=#{@snippet.secret_token}"))
    end

    it 'returns view raw button of embedded snippets for project snippets' do
      @snippet = create(:project_snippet, :public)

      expect(subject).to eq(download_link("http://test.host/#{@snippet.project.path_with_namespace}/snippets/#{@snippet.id}/raw"))
    end

    def download_link(url)
      "<a class=\"btn\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{url}\">#{external_snippet_icon('doc-code')}</a>"
    end
  end

  describe '#embedded_snippet_download_button' do
    subject { embedded_snippet_download_button }

    it 'returns download button of embedded snippets for personal snippets' do
      @snippet = create(:personal_snippet, :public)

      expect(subject).to eq(download_link("http://test.host/snippets/#{@snippet.id}/raw?inline=false"))
    end

    it 'returns download button of embedded snippets for secret personal snippets' do
      @snippet = create(:personal_snippet, :secret)

      expect(subject).to eq(download_link("http://test.host/snippets/#{@snippet.id}/raw?inline=false&amp;token=#{@snippet.secret_token}"))
    end

    it 'returns download button of embedded snippets for project snippets' do
      @snippet = create(:project_snippet, :public)

      expect(subject).to eq(download_link("http://test.host/#{@snippet.project.path_with_namespace}/snippets/#{@snippet.id}/raw?inline=false"))
    end

    def download_link(url)
      "<a class=\"btn\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{url}\">#{external_snippet_icon('download')}</a>"
    end
  end

  describe '#snippet_embed_tag' do
    subject { snippet_embed_tag(snippet) }

    context 'personal snippets' do
      let(:snippet) { public_personal_snippet }

      context 'public' do
        it 'returns a script tag with the snippet full url' do
          expect(subject).to eq(script_embed("http://test.host/snippets/#{snippet.id}.js"))
        end
      end

      context 'secret snippets' do
        let(:snippet) { secret_snippet }

        it 'returns a script tag with the snippet full url' do
          expect(subject).to eq(script_embed("http://test.host/snippets/#{snippet.id}.js?token=#{snippet.secret_token}"))
        end
      end
    end

    context 'project snippets' do
      let(:snippet) { public_project_snippet }

      it 'returns a script tag with the snippet full url' do
        expect(subject).to eq(script_embed("http://test.host/#{snippet.project.path_with_namespace}/snippets/#{snippet.id}.js"))
      end
    end

    def script_embed(url)
      "<script src=\"#{url}\"></script>"
    end
  end

  describe '#download_raw_snippet_button' do
    subject { download_raw_snippet_button(snippet) }

    context 'with personal snippet' do
      let(:snippet) { public_personal_snippet }

      context 'public' do
        it 'returns the download button' do
          expect(subject).to eq(download_link("/snippets/#{snippet.id}/raw?inline=false"))
        end
      end

      context 'secret' do
        let(:snippet) { secret_snippet }

        it 'returns the download button' do
          expect(subject).to eq(download_link("/snippets/#{snippet.id}/raw?inline=false&amp;token=#{snippet.secret_token}"))
        end
      end
    end

    context 'with project snippet' do
      let(:snippet) { public_project_snippet }

      it 'returns the download button' do
        expect(subject).to eq(download_link("/#{snippet.project.path_with_namespace}/snippets/#{snippet.id}/raw?inline=false"))
      end
    end

    def download_link(url)
      "<a target=\"_blank\" rel=\"noopener noreferrer\" class=\"btn btn-sm has-tooltip\" title=\"Download\" data-container=\"body\" href=\"#{url}\"><i aria-hidden=\"true\" data-hidden=\"true\" class=\"fa fa-download\"></i></a>"
    end
  end

  describe '#snippet_badge' do
    let(:snippet) { build(:personal_snippet, visibility) }

    subject { snippet_badge(snippet) }

    context 'when snippet is private' do
      let(:visibility) { :private }

      it 'returns the snippet badge' do
        expect(subject).to eq "<span class=\"badge badge-gray\"><i class=\"fa fa-lock\"></i> private</span>"
      end
    end

    context 'when snippet is public' do
      let(:visibility) { :public }

      it 'does not return anything' do
        expect(subject).to be_nil
      end
    end

    context 'when snippet is internal' do
      let(:visibility) { :internal }

      it 'does not return anything' do
        expect(subject).to be_nil
      end
    end

    context 'when snippet is secret' do
      let(:visibility) { :secret }

      it 'returns the snippet badge' do
        expect(subject).to eq "<span class=\"badge badge-gray\"><i class=\"fa fa-user-secret\"></i> secret</span>"
      end
    end
  end

  describe '#snippet_embed_input' do
    subject { snippet_embed_input(snippet) }

    context 'with PersonalSnippet' do
      let(:snippet) { public_personal_snippet }

      it 'returns the input component' do
        expect(subject).to eq embed_input(snippet_url(snippet))
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { public_project_snippet }

      it 'returns the input component' do
        expect(subject).to eq embed_input(project_snippet_url(snippet.project, snippet))
      end
    end

    def embed_input(url)
      "<input type=\"text\" readonly=\"readonly\" class=\"js-snippet-url-area snippet-embed-input form-control\" data-url=\"#{url}\" value=\"<script src=&quot;#{url}.js&quot;></script>\" autocomplete=\"off\"></input>"
    end
  end
end
