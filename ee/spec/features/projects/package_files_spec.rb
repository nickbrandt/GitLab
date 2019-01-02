# frozen_string_literal: true

require 'spec_helper'

describe 'PackageFiles' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:package) { create(:maven_package, project: project) }
  let!(:package_file) { package.package_files.first }

  before do
    sign_in(user)
    stub_licensed_features(packages: true)
  end

  context 'user with master role' do
    before do
      project.add_master(user)
    end

    it 'allows file download from package page' do
      visit project_package_path(project, package)

      click_link package_file.file_name

      expect(status_code).to eq(200)
      expect(page.response_headers['Content-Type']).to eq 'application/xml'
      expect(page.response_headers['Content-Transfer-Encoding']).to eq 'binary'
    end

    it 'allows direct download by url' do
      visit download_project_package_file_path(project, package_file)

      expect(status_code).to eq(200)
    end

    it 'does not allow download of package belonging to different project' do
      another_package = create(:maven_package)
      another_file = another_package.package_files.first

      visit download_project_package_file_path(project, another_file)

      expect(status_code).to eq(404)
    end

    it 'gives 404 when packages feature is not available' do
      stub_licensed_features(packages: false)

      visit download_project_package_file_path(project, package_file)

      expect(status_code).to eq(404)
    end
  end

  it 'does not allow direct download when no access to the project' do
    visit download_project_package_file_path(project, package_file)

    expect(status_code).to eq(404)
  end

  it 'gives 404 when no package file exist' do
    visit download_project_package_file_path(project, '9999')

    expect(status_code).to eq(404)
  end
end
