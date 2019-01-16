# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20190111231855_fix_import_data_auth_method_for_mirrors.rb')

describe FixImportDataAuthMethodForMirrors, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create(id: 1000, name: 'gitlab-org', path: 'gitlab-test') }

  def create_mirror(import_url:, enable_import_data: true)
    project = described_class::Project.new(namespace_id: namespace.id, mirror: true, import_url: import_url)
    described_class::ProjectImportData.new(project: project) if enable_import_data
    project
  end

  def set_credentials(project, auth_type:, user: nil, password: nil)
    project.import_data.credentials =
      {
        auth_method: auth_type,
        user: user,
        password: password
      }

    project.import_data.save
  end

  describe '#up' do
    let!(:http_project) { create_mirror(import_url: 'https://example.com') }
    let!(:bad_http_project) { create_mirror(import_url: 'https://bad.example.com') }
    let!(:git_project) { create_mirror(import_url: 'git://example.com') }
    let!(:null_project) { create_mirror(import_url: nil, enable_import_data: false) }

    before do
      set_credentials(http_project, auth_type: 'password', user: 'foo', password: 'pass')
      set_credentials(bad_http_project, auth_type: 'ssh_public_key', user: 'bar', password: 'baz')
      set_credentials(git_project, auth_type: 'ssh_public_key')
    end

    it 'fixes the auth method for projects' do
      subject.up

      expect(http_project.reload.import_data.auth_method).to eq('password')
      expect(bad_http_project.reload.import_data.auth_method).to eq('password')
      expect(git_project.reload.import_data.auth_method).to eq('ssh_public_key')
    end

    it 'retains current auth settings' do
      expect { subject.up }.not_to change { git_project.import_data.credentials }

      http_project.reload
      expect(http_project.import_data.credentials[:user]).to eq('foo')
      expect(http_project.import_data.credentials[:password]).to eq('pass')

      bad_http_project.reload
      expect(bad_http_project.import_data.credentials[:user]).to eq('bar')
      expect(bad_http_project.import_data.credentials[:password]).to eq('baz')
    end

    it 'handles bad SSL decryptions' do
      allow_any_instance_of(described_class::Project).to receive(:import_data).and_raise(OpenSSL::Cipher::CipherError)

      expect { subject.up }.not_to change { described_class::ProjectImportData.find_by(project_id: bad_http_project.id).credentials }
    end
  end
end
