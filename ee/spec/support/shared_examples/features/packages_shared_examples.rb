# frozen_string_literal: true

RSpec.shared_examples 'packages list' do |check_project_name: false|
  it 'shows a list of packages' do
    wait_for_requests

    packages.each_with_index do |pkg, index|
      package_row = package_table_row(index)

      expect(package_row).to have_content(pkg.name)
      expect(package_row).to have_content(pkg.version)
      expect(package_row).to have_content(pkg.project.name) if check_project_name
    end
  end

  def package_table_row(index)
    page.all(packages_table_selector)[index].text
  end
end

RSpec.shared_examples 'package details link' do |property|
  let(:package) { packages.first }

  it 'navigates to the correct url' do
    page.within(packages_table_selector) do
      click_link package.name
    end

    expect(page).to have_current_path(project_package_path(package.project, package))

    page.within('.detail-page-header') do
      expect(page).to have_content(package.name)
    end

    page.within('[data-qa-selector="package_information_content"]') do
      expect(page).to have_content('Installation')
      expect(page).to have_content('Registry Setup')
    end
  end
end

RSpec.shared_examples 'when there are no packages' do
  it 'displays the empty message' do
    expect(page).to have_content('There are no packages yet')
  end
end

def packages_table_selector
  '[data-qa-selector="packages-table"] tbody tr'
end
