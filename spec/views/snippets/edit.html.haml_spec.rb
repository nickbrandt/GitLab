# frozen_string_literal: true

require 'spec_helper'

describe 'snippets/edit' do
  let_it_be(:snippet) { create(:personal_snippet) }
  let(:user) { snippet.author }
  let(:flag_value) { true }

  before do
    stub_feature_flags(secret_snippets: flag_value)

    assign(:snippet, snippet)

    allow(controller).to receive(:current_user).and_return(user)

    render
  end

  it 'shows secret visibility radio' do
    expect(rendered).to have_css('input#personal_snippet_visibility_level_secret')
  end

  it 'shows secret visibility icon' do
    expect(rendered).to have_css('label[for="personal_snippet_visibility_level_secret"] i.fa-user-secret')
  end

  it 'shows secret visibility description' do
    expect(rendered).to have_content('The snippet can be accessed without any authentication, but is not searchable')
  end

  it 'shows secret hidden input' do
    expect(rendered).to have_css('input.snippet_secret', visible: false)
  end

  context 'when secret_snippets feature flag is disabled' do
    let(:flag_value) { false }

    it 'does not show secret visibility radio' do
      expect(rendered).not_to have_css('input#personal_snippet_visibility_level_secret')
    end

    it 'does not show secret visibility icon' do
      expect(rendered).not_to have_css('label[for="personal_snippet_visibility_level_secret"] i.fa-user-secret')
    end

    it 'does not show secret visibility description' do
      expect(rendered).not_to have_content('The snippet can be accessed without any authentication, but is not searchable')
    end

    it 'does not show secret hidden input' do
      expect(rendered).not_to have_css('input.snippet_secret', visible: false)
    end
  end
end
