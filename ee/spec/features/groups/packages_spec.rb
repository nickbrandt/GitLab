# frozen_string_literal: true

require 'spec_helper'

describe 'Group Packages' do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }

  before do
    sign_in(user)
    group.add_maintainer(user)
    stub_licensed_features(packages: true)
  end

  context 'packages feature is not available because of license' do
    before do
      stub_licensed_features(packages: false)
    end

    it 'gives 404' do
      visit_group_packages

      expect(page).to have_gitlab_http_status(404)
    end
  end

  context 'packages feature is disabled by config' do
    before do
      allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
    end

    it 'gives 404' do
      visit_group_packages

      expect(page).to have_gitlab_http_status(404)
    end
  end

  context 'when there are no packages' do
    it 'shows no packages message' do
      visit_group_packages

      expect(page).to have_content 'There are no packages yet'
    end
  end

  context 'when there are packages' do
    let!(:package) { create(:maven_package, project: project) }

    it 'shows list of packages' do
      visit_group_packages

      expect(page).to have_content(package.name)
      expect(page).to have_content(package.version)
    end
  end

  def visit_group_packages
    visit group_packages_path(group)
  end
end
