# frozen_string_literal: true

RSpec.shared_examples 'handling file uploads' do |shared_examples_name|
  context 'with object storage disabled' do
    before do
      expect_next_instance_of(::UploadedFile) do |uploaded_file|
        expect(uploaded_file.tempfile).not_to be nil
        expect(uploaded_file.remote_id).to eq ''
      end
    end

    context 'with upload_middleware_jwt_params_handler disabled' do
      before do
        stub_feature_flags(upload_middleware_jwt_params_handler: false)

        expect_next_instance_of(Gitlab::Middleware::Multipart::Handler) do |handler|
          expect(handler).to receive(:with_open_files).and_call_original
        end
      end

      it_behaves_like shared_examples_name
    end

    context 'with upload_middleware_jwt_params_handler enabled' do
      before do
        stub_feature_flags(upload_middleware_jwt_params_handler: true)

        expect_next_instance_of(Gitlab::Middleware::Multipart::HandlerForJWTParams) do |handler|
          expect(handler).to receive(:with_open_files).and_call_original
        end
      end

      it_behaves_like shared_examples_name
    end
  end

  context 'with object storage enabled', :object_storage do
    before do
      expect_next_instance_of(::UploadedFile) do |uploaded_file|
        expect(uploaded_file.tempfile).to be nil
        expect(uploaded_file.remote_id).not_to be nil
      end
    end

    context 'with upload_middleware_jwt_params_handler disabled' do
      before do
        stub_feature_flags(upload_middleware_jwt_params_handler: false)

        expect_next_instance_of(Gitlab::Middleware::Multipart::Handler) do |handler|
          expect(handler).to receive(:with_open_files).and_call_original
        end
      end

      it_behaves_like shared_examples_name
    end

    context 'with upload_middleware_jwt_params_handler enabled' do
      before do
        stub_feature_flags(upload_middleware_jwt_params_handler: true)

        expect_next_instance_of(Gitlab::Middleware::Multipart::HandlerForJWTParams) do |handler|
          expect(handler).to receive(:with_open_files).and_call_original
        end
      end

      it_behaves_like shared_examples_name
    end
  end
end
