# frozen_string_literal: true

require 'spec_helper'

describe 'Snippets' do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      visit snippets_path(username: project.owner.username)
    end

    it_behaves_like 'paginated snippets'
  end

  describe 'when feature flag is enabled' do
    let(:user) { create(:user) }
    let!(:snippets) { create(:personal_snippet, :public, author: user) }

    before do
      stub_feature_flags(snippets_vue: true)
      visit snippet_path(1)
    end

    it 'should render Vue application' do
      expect(page).to have_selector('#js-snippet-view')
      expect(page).not_to have_selector('.personal-snippets')
    end
  end

  describe 'when feature flag is disabled' do
    let(:user) { create(:user) }
    let!(:snippets) { create(:personal_snippet, :public, author: user) }

    before do
      stub_feature_flags(snippets_vue: false)
      visit snippet_path(1)
    end

    it 'should render HAML application and not Vue' do
      expect(page).not_to have_selector('#js-snippet-view')
      expect(page).to have_selector('.personal-snippets')
    end
  end
end
