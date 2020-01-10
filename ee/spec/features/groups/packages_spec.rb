# frozen_string_literal: true

require 'spec_helper'

describe 'Group Packages' do
  include SortingHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    sign_in(user)
    group.add_maintainer(user)
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

    context 'sorting when there are packages' do
      let!(:second_project) { create(:project, name: 'second-project', group: group) }

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
          project: second_project)
      end

      it 'sorts by created date descending by default' do
        visit group_packages_path(group)

        expect(sort_dropdown_button_text).to eq(sort_title_created_date)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'handles an invalid param' do
        visit group_packages_path(group, sort: 'garbage') # bad sort param

        expect(sort_dropdown_button_text).to eq(sort_title_created_date)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by created date descending' do
        visit group_packages_path(group, sort: sort_value_recently_created)

        expect(sort_dropdown_button_text).to eq(sort_title_created_date)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by created date ascending' do
        visit group_packages_path(group, sort: sort_value_oldest_created)

        expect(sort_dropdown_button_text).to eq(sort_title_created_date)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end

      it 'sorts by name descending' do
        visit group_packages_path(group, sort: sort_value_name_desc)

        expect(sort_dropdown_button_text).to eq(sort_title_name)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by name ascending' do
        visit group_packages_path(group, sort: sort_value_name)

        expect(sort_dropdown_button_text).to eq(sort_title_name)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end

      it 'sorts by version descending' do
        visit group_packages_path(group, sort: sort_value_version_desc)

        expect(sort_dropdown_button_text).to eq(sort_title_version)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by version ascending' do
        visit group_packages_path(group, sort: sort_value_version_asc)

        expect(sort_dropdown_button_text).to eq(sort_title_version)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end

      it 'sorts by project descending' do
        visit group_packages_path(group, sort: sort_value_project_name_desc)

        expect(sort_dropdown_button_text).to eq(sort_title_project_name)
        expect(first_package).to include(bbb_package.name)
        expect(last_package).to include(aaa_package.name)
      end

      it 'sorts by project ascending' do
        visit group_packages_path(group, sort: sort_value_project_name_asc)

        expect(sort_dropdown_button_text).to eq(sort_title_project_name)
        expect(first_package).to include(aaa_package.name)
        expect(last_package).to include(bbb_package.name)
      end
    end

    context 'sorting different types of packages' do
      let!(:maven_package) { create(:maven_package, project: project) }
      let!(:npm_package) { create(:npm_package, project: project) }

      it 'sorts by type descending' do
        visit group_packages_path(group, sort: sort_value_type_desc)

        expect(sort_dropdown_button_text).to eq(sort_title_type)
        expect(first_package).to include(npm_package.name)
        expect(last_package).to include(maven_package.name)
      end

      it 'sorts by type ascending' do
        visit group_packages_path(group, sort: sort_value_type_asc)

        expect(sort_dropdown_button_text).to eq(sort_title_type)
        expect(first_package).to include(maven_package.name)
        expect(last_package).to include(npm_package.name)
      end
    end
  end

  context 'wtih vue_package_list feature flag enabled' do
    before do
      stub_feature_flags(vue_package_list: true)
      visit_group_packages
    end

    it 'load an empty placeholder' do
      expect(page.has_selector?('#js-vue-packages-list')).to be_truthy
    end
  end

  def visit_group_packages
    visit group_packages_path(group)
  end

  def first_package
    page.all('[data-qa-selector="package-row"]').first.text
  end

  def last_package
    page.all('[data-qa-selector="package-row"]').last.text
  end

  def sort_dropdown_button_text
    page.find('[data-qa-selector="sort-dropdown-button"]').text
  end
end
