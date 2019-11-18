# frozen_string_literal: true

require 'spec_helper'

describe ConanPackagePresenter do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '#recipe_urls' do
    subject { described_class.new(recipe, user, project).recipe_urls }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conanfile.py" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#recipe_snapshot' do
    subject { described_class.new(recipe, user, project).recipe_snapshot }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conanfile.py" => '12345abcde',
          "conanmanifest.txt" => '12345abcde'
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#package_urls' do
    subject { described_class.new(recipe, user, project).package_urls }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conaninfo.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conaninfo.txt",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conanmanifest.txt",
          "conan_package.tgz" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conan_package.tgz"
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#package_snapshot' do
    subject { described_class.new(recipe, user, project).package_snapshot }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conaninfo.txt" => '12345abcde',
          "conanmanifest.txt" => '12345abcde',
          "conan_package.tgz" => '12345abcde'
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end
