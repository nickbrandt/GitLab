# frozen_string_literal: true

require 'spec_helper'

describe 'Packages' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_master(user)
    stub_licensed_features(packages: true)
  end

  context 'packages feature is not available because of license' do
    before do
      stub_licensed_features(packages: false)
    end

    it 'gives 404' do
      visit_project_packages

      expect(status_code).to eq(404)
    end
  end

  context 'packages feature is disabled by config' do
    before do
      allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
    end

    it 'gives 404' do
      visit_project_packages

      expect(status_code).to eq(404)
    end
  end

  context 'when there are no packages' do
    it 'shows no packages message' do
      visit_project_packages

      expect(page).to have_content 'There are no packages yet'
    end
  end

  context 'when there are packages' do
    let!(:package) { create(:maven_package, project: project) }

    before do
      visit_project_packages
    end

    it 'shows list of packages' do
      expect(page).to have_content(package.name)
      expect(page).to have_content(package.version)
    end

    it 'shows a single package' do
      click_on package.name

      expect(page).to have_content(package.name)
      expect(page).to have_content(package.version)

      package.package_files.each do |package_file|
        expect(page).to have_content(package_file.file_name)
      end
    end

    it 'removes package' do
      click_link 'Delete Package'

      expect(page).to have_content 'Package was removed'
      expect(page).not_to have_content(package.name)
    end
  end

  def visit_project_packages
    visit project_packages_path(project)
  end
end
