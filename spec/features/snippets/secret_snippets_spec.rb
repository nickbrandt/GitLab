# frozen_string_literal: true

require 'spec_helper'

describe 'Secret Snippets', :js do
  let_it_be(:snippet) { create(:personal_snippet, :secret) }
  let_it_be(:user) { create(:user) }
  let(:author) { snippet.author }
  let(:token) { snippet.secret_token }

  before do
    sign_in(user) if user
  end

  shared_examples 'user cannot access' do
    it 'secret snippet' do
      visit snippet_path(snippet)
      wait_for_requests

      expect(page).not_to have_content(snippet.content)
    end

    it 'raw secret snippet' do
      visit raw_snippet_path(snippet)

      expect(page).not_to have_content(snippet.content)
    end
  end

  shared_examples 'user can access' do
    it 'secret snippet' do
      visit snippet_path(snippet, token: token)
      wait_for_requests

      expect(page).to have_content(snippet.content)
    end

    it 'raw secret snippet' do
      visit raw_snippet_path(snippet, token: token)

      expect(page).to have_content(snippet.content)
    end
  end

  context 'when user is unauthenticated' do
    let(:user) { nil }

    context 'without the snippet token' do
      it_behaves_like 'user cannot access'
    end

    context 'with the snippet token' do
      it_behaves_like 'user can access'
    end
  end

  context 'when user is authenticated' do
    context 'without the snippet token' do
      it_behaves_like 'user cannot access'
    end

    context 'with the snippet token' do
      it_behaves_like 'user can access'
    end
  end

  context 'when user is the author' do
    let(:user) { author }

    context 'without the snippet token' do
      let(:token) { nil }

      it_behaves_like 'user can access'
    end

    context 'with the snippet token' do
      it_behaves_like 'user can access'
    end
  end

  context 'when user is an admin uthor' do
    let(:user) { create(:admin) }

    context 'without the snippet token' do
      let(:token) { nil }

      it_behaves_like 'user can access'
    end

    context 'with the snippet token' do
      it_behaves_like 'user can access'
    end
  end
end
