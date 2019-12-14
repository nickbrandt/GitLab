# frozen_string_literal: true

require 'spec_helper'

describe 'Packages' do
  include SortingHelper

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_master(user)
    stub_licensed_features(packages: true)
  end

  context 'with vue_package_list feature flag disabled' do
    before do
      stub_feature_flags(vue_package_list: false)
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

      it 'hides a package without a version from the list' do
        package.update!(version: nil)

        visit_project_packages

        expect(page).not_to have_content(package.name)
      end

      it 'shows a single package', :js do
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

    context 'sorting when there are packages' do
      let!(:aaa_package) do
        create(
          :maven_package,
          name: 'aaa/company/app/my-app',
          version: '1.0-SNAPSHOT',
          project: project)
      end

      let!(:bbb_package) do
        create(
          :maven_package,
          name: 'bbb/company/app/my-app',
          version: '1.1-SNAPSHOT',
          project: project)
      end

      it 'sorts by created date descending' do
        visit project_packages_path(project, sort: sort_value_created_date)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by created date ascending' do
        visit project_packages_path(project, sort: sort_value_oldest_created)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end

      it 'sorts by name descending' do
        visit project_packages_path(project, sort: sort_value_name_desc)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by name ascending' do
        visit project_packages_path(project, sort: sort_value_name)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end

      it 'sorts by version descending' do
        visit project_packages_path(project, sort: sort_value_version_desc)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by version ascending' do
        visit project_packages_path(project, sort: sort_value_version_asc)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end
    end

    context 'sorting different types of packages' do
      let!(:maven_package) { create(:maven_package, project: project) }
      let!(:npm_package) { create(:npm_package, project: project) }

      it 'sorts by type descending' do
        visit project_packages_path(project, sort: sort_value_type_desc)
        expect(first_package).to include(npm_package.name)
        expect(last_package).to include(maven_package.name)
      end

      it 'sorts by type ascending' do
        visit project_packages_path(project, sort: sort_value_type_asc)
        expect(first_package).to include(maven_package.name)
        expect(last_package).to include(npm_package.name)
      end
    end
  end

  context 'wtih vue_package_list ff enabled' do
    before do
      stub_feature_flags(vue_package_list: true)
      visit_project_packages
    end

    it 'load an empty placeholder' do
      expect(page.has_selector?('#js-vue-packages-list')).to be_truthy
    end
  end

  def visit_project_packages
    visit project_packages_path(project)
  end

  def first_package
    page.all('.table-holder .package-row').first.text
  end

  def last_package
    page.all('.table-holder .package-row').last.text
  end
end
