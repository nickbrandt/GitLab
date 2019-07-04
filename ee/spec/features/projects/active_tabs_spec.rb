require 'spec_helper'

describe 'Project active tab' do
  let(:user) { create :user }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def click_tab(title)
    page.within '.sidebar-top-level-items > .active' do
      click_link(title)
    end
  end

  shared_examples 'page has active tab' do |title|
    it "activates #{title} tab" do
      expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
      expect(find('.sidebar-top-level-items > li.active')).to have_content(title)
    end
  end

  shared_examples 'page has active sub tab' do |title|
    it "activates #{title} sub tab" do
      expect(page).to have_selector('.sidebar-sub-level-items  > li.active:not(.fly-out-top-item)', count: 1)
      expect(find('.sidebar-sub-level-items > li.active:not(.fly-out-top-item)'))
        .to have_content(title)
    end
  end

  context 'on project Home/Dependency List' do
    before do
      stub_licensed_features(dependency_list: true)
      visit project_path(project)
      click_tab('Dependency List')
    end

    it_behaves_like 'page has active tab', 'Project'
    it_behaves_like 'page has active sub tab', 'Dependency List'
  end
end

