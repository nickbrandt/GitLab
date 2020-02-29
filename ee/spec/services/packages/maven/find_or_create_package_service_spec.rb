# frozen_string_literal: true
require 'spec_helper'

describe Packages::Maven::FindOrCreatePackageService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:app_name) { 'my-app' }
  let_it_be(:path) { "my/company/app/#{app_name}" }
  let_it_be(:version) { '1.0.0' }
  let_it_be(:path_with_version) { "#{path}/#{version}" }
  let_it_be(:params) do
    {
      name: app_name,
      path: path_with_version,
      version: version
    }
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute }

    context 'without any existing package' do
      it 'creates a package' do
        expect { subject }.to change { Packages::Package.count }.by(1)
      end
      it 'assigns a numerical version to a release package' do
        expect(subject.version).to eq('1.0.0')
      end
    end

    context 'when publishing a Snapshot' do
      let_it_be(:snapshot_path) { "my/company/app/my-app/1.0.1-SNAPSHOT" }
      let_it_be(:params) do
        {
          path: snapshot_path,
          name: "my-app",
          version: "1.0.1-SNAPSHOT"
        }
      end

      it 'Sets the version value with the correct -SNAPSHOT extension' do
        package_name, _, snapshot_version = snapshot_path.rpartition('/')
        snapshot_package = described_class.new(project, user, params).execute

        expect(snapshot_package.version).to eq(snapshot_version)
        expect(snapshot_package.name).to eq(package_name)
      end
    end

    context 'with an existing package' do
      let_it_be(:existing_package) { create(:maven_package, name: path, version: version, project: project) }

      it { is_expected.to eq existing_package }
      it "doesn't create a new package" do
        expect { subject }
          .to not_change { Packages::Package.count }
      end
    end
  end
end
