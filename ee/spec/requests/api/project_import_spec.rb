# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectImport do
  include ExternalAuthorizationServiceHelpers

  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    namespace.add_owner(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /projects/import' do
    let(:override_params) { { 'external_authorization_classification_label' => 'Hello world' } }

    before do
      enable_external_authorization_service_check
      stub_licensed_features(external_authorization_service_api_management: true)
    end

    subject do
      Sidekiq::Testing.inline! do
        post api('/projects/import', user),
             params: {
               path: 'test-import',
               file: fixture_file_upload(file),
               namespace: namespace.id,
               override_params: override_params
             }
      end
    end

    it 'overrides the classification label' do
      subject

      import_project = Project.find(json_response['id'])
      expect(import_project.external_authorization_classification_label).to eq('Hello world')
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(external_authorization_service_api_management: false)
      end

      it 'uses the default the classification label and ignores override param' do
        subject

        import_project = Project.find(json_response['id'])
        expect(import_project.external_authorization_classification_label).to eq('default_label')
      end
    end
  end
end
