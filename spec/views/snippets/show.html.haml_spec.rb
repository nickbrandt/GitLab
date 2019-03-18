# frozen_string_literal: true

require 'spec_helper'

describe 'snippets/show' do
  let(:user) { snippet.author }

  before do
    stub_feature_flags(snippets_vue: false)

    # Since the show view requires the user status loaded
    # we can't just assign the `snippet`
    assign(:snippet, PersonalSnippet.find_by(id: snippet.id))
    assign(:note, Note.new(noteable: snippet))
    assign(:noteable, snippet)
    assign(:discussions, snippet.discussions)

    controller.params[:controller] = 'snippets'
    controller.params[:action] = 'show'
    controller.params[:id] = snippet.id
    allow(controller).to receive(:current_user).and_return(user)

    render
  end

  context 'when snippet is secret' do
    let_it_be(:snippet) { create(:personal_snippet, :secret) }

    it 'shows secret description tooltip' do
      expect(rendered).to have_css('.detail-page-header-body .snippet-box[title="The snippet can be accessed without any authentication, but is not searchable."]')
    end

    it 'shows secret icon' do
      expect(rendered).to have_css('.snippet-box i.fa-user-secret')
    end

    it 'shows secret icon' do
      expect(rendered).to have_content('Secret')
    end
  end
end
