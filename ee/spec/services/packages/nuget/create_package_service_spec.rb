# frozen_string_literal: true
require 'spec_helper'

describe Packages::Nuget::CreatePackageService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    it 'creates the package' do
      expect { subject }.to change { Packages::Package.count }.by(1)
      package = Packages::Package.last

      expect(package).to be_valid
      expect(package.name).to eq(Packages::Nuget::CreatePackageService::PACKAGE_NAME)
      expect(package.version).to eq(Packages::Nuget::CreatePackageService::PACKAGE_VERSION)
      expect(package.package_type).to eq('nuget')
    end
  end
end
