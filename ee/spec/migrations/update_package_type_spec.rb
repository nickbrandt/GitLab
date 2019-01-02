# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20181220165848_update_package_type.rb')

describe UpdatePackageType, :migration do
  describe '#up' do
    let(:namespace) { table(:namespaces).create(path: 'ns', name: 'Namespace') }
    let(:project)   { table(:projects).create(namespace_id: namespace.id, path: 'pj') }
    let!(:package)  { table(:packages_packages).create(name: 'foo', version: '1.0.0', project_id: project.id) }

    it 'updates package_type from nil to 1' do
      migrate!

      expect(package.reload.package_type).to eq(1)
    end
  end
end
