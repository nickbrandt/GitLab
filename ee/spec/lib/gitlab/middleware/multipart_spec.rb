# frozen_string_literal: true

require 'spec_helper'

require 'tempfile'

RSpec.describe Gitlab::Middleware::Multipart do
  include_context 'multipart middleware context'

  describe '#call' do
    context 'with packages storage' do
      using RSpec::Parameterized::TableSyntax

      let(:storage_path) { 'shared/packages' }

      RSpec.shared_examples 'allowing the multipart upload' do
        it 'allows files to be uploaded' do
          with_tmp_dir('tmp/uploads', storage_path) do |dir, env|
            allow(Packages::PackageFileUploader).to receive(:root).and_return(File.join(dir, storage_path))

            expect(app).to receive(:call) do |env|
              expect(get_params(env)['file']).to be_a(::UploadedFile)
            end

            middleware.call(env)
          end
        end
      end

      RSpec.shared_examples 'not allowing the multipart upload when package upload path is used' do
        it 'does not allow files to be uploaded' do
          with_tmp_dir('tmp/uploads', storage_path) do |dir, env|
            # with_tmp_dir sets the same workhorse_upload_path for all Uploaders,
            # so we have to prevent JobArtifactUploader and LfsObjectUploader to
            # allow the tested path
            allow(JobArtifactUploader).to receive(:workhorse_upload_path).and_return(Dir.tmpdir)
            allow(LfsObjectUploader).to receive(:workhorse_upload_path).and_return(Dir.tmpdir)

            status, headers, body = middleware.call(env)

            expect(status).to eq(400)
            expect(headers).to eq({ 'Content-Type' => 'text/plain' })
            expect(body).to start_with('insecure path used')
          end
        end
      end

      RSpec.shared_examples 'adding package storage to multipart allowed paths' do
        before do
          expect(::Packages::PackageFileUploader).to receive(:workhorse_upload_path).and_call_original
        end

        it_behaves_like 'allowing the multipart upload'
      end

      RSpec.shared_examples 'not adding package storage to multipart allowed paths' do
        before do
          expect(::Packages::PackageFileUploader).not_to receive(:workhorse_upload_path)
        end

        it_behaves_like 'not allowing the multipart upload when package upload path is used'
      end

      where(:object_storage_enabled, :direct_upload_enabled, :example_name) do
        false | true  | 'adding package storage to multipart allowed paths'
        false | false | 'adding package storage to multipart allowed paths'
        true  | true  | 'not adding package storage to multipart allowed paths'
        true  | false | 'adding package storage to multipart allowed paths'
      end

      with_them do
        before do
          stub_config(packages: {
            enabled: true,
            object_store: {
              enabled: object_storage_enabled,
              direct_upload: direct_upload_enabled
            },
            storage_path: storage_path
          })
        end

        it_behaves_like params[:example_name]
      end
    end
  end
end
