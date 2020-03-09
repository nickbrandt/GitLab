# frozen_string_literal: true

require 'spec_helper'

describe TerraformStateUploader do
  subject { terraform_state.file }

  let(:terraform_state) { create(:terraform_state, file: fixture_file_upload('spec/fixtures/terraform.tfstate')) }

  before do
    stub_terraform_state_object_storage
  end

  describe '#filename' do
    it 'contains the ID of the terraform state record' do
      expect(subject.filename).to include(terraform_state.id.to_s)
    end
  end

  describe '#store_dir' do
    it 'contains the ID of the project' do
      expect(subject.store_dir).to include(terraform_state.project_id.to_s)
    end
  end

  describe '#key' do
    it 'creates a digest with a secret key and the project id' do
      expect(OpenSSL::HMAC)
        .to receive(:digest)
        .with('SHA256', Gitlab::Application.secrets.db_key_base, terraform_state.project_id.to_s)
        .and_return('digest')

      expect(subject.key).to eq('digest')
    end
  end

  describe 'encryption' do
    it 'encrypts the stored file' do
      expect(subject.file.read).not_to eq(fixture_file('terraform.tfstate'))
    end

    it 'decrypts the file when reading' do
      expect(subject.read).to eq(fixture_file('terraform.tfstate'))
    end
  end
end
