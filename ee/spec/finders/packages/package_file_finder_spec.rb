# frozen_string_literal: true
require 'spec_helper'

describe Packages::PackageFileFinder do
  let_it_be(:package) { create(:maven_package) }
  let_it_be(:package_file) { package.package_files.first }
  let(:package_file_name) { package_file.file_name }
  let(:params) { {} }

  RSpec.shared_examples 'package file finder examples' do
    it { is_expected.to eq(package_file) }

    context 'with conan_file_type' do
      let_it_be(:package) { create(:conan_package) }
      # conan packages contain a conanmanifest.txt file for both conan_file_types
      let(:package_file_name) { 'conanmanifest.txt' }
      let(:params) { { conan_file_type: :recipe_file } }

      it { expect(subject.conan_file_type).to eq('recipe_file') }
    end

    context 'with file_name_like' do
      let(:package_file_name) { package_file.file_name.upcase }
      let(:params) { { with_file_name_like: true } }

      it { is_expected.to eq(package_file) }
    end
  end

  describe '#execute' do
    subject { described_class.new(package, package_file_name, params).execute }

    it_behaves_like 'package file finder examples'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect(subject).to be_nil }
    end
  end

  describe '#execute!' do
    subject { described_class.new(package, package_file_name, params).execute! }

    it_behaves_like 'package file finder examples'

    context 'with unknown file_name' do
      let(:package_file_name) { 'unknown.jpg' }

      it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
