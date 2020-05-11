# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Storage::S3Client, :aws_s3 do
  let!(:region) { 'eu-west-1' }
  let!(:bucket_name) { 'bucket_name' }
  let!(:access_key_id) { 'key_id' }
  let!(:secret_access_key) { 'secret' }

  let!(:client) do
    described_class.new(
      region: region, bucket_name: bucket_name, access_key_id: access_key_id,
      secret_access_key: secret_access_key
    )
  end

  describe '#upload_object' do
    let(:key) { 'key' }
    let(:content) { 'content' }

    subject(:result) { client.upload_object(key, content) }

    context 'when successful' do
      it 'returns true' do
        stub_responses(:put_object)

        expect(result).to eq(true)
      end
    end

    context 'when failed' do
      let(:aws_error) { 'SomeError' }

      it 'raises an error' do
        stub_responses(:put_object, aws_error)

        msg = error_message(aws_error, key: key)
        expect { result }.to raise_error(StatusPage::Storage::Error, msg)
      end
    end
  end

  describe '#delete_object' do
    let(:key) { 'key' }

    subject(:result) { client.delete_object(key) }

    it 'returns true' do
      stub_responses(:delete_object)

      expect(result).to eq(true)
    end

    context 'when failed' do
      let(:aws_error) { 'SomeError' }

      it 'raises an error' do
        stub_responses(:delete_object, aws_error)

        msg = error_message(aws_error, key: key)
        expect { result }.to raise_error(StatusPage::Storage::Error, msg)
      end
    end
  end

  describe '#recursive_delete' do
    let(:key_prefix) { 'key_prefix/' }
    let(:aws_client) { client.send('client') }

    subject(:result) { client.recursive_delete(key_prefix) }

    context 'when successful' do
      include_context 'list_objects_v2 result'

      it 'sends keys for batch delete' do
        expect(aws_client).to receive(:delete_objects).with(delete_objects_data(key_list_1))
        expect(aws_client).to receive(:delete_objects).with(delete_objects_data(key_list_2))

        result
      end

      it 'returns true' do
        expect(result).to eq(true)
      end
    end

    context 'list_object exeeds upload limit' do
      include_context 'oversized list_objects_v2 result'

      it 'respects upload limit' do
        expect(aws_client).to receive(:delete_objects).with(delete_objects_data(keys_page_1))
        expect(aws_client).not_to receive(:delete_objects).with(delete_objects_data(keys_page_2))

        result
      end
    end

    context 'when list_object returns no objects' do
      include_context 'no objects list_objects_v2 result'

      it 'does not attempt to delete' do
        expect(aws_client).not_to receive(:delete_objects).with(delete_objects_data(key_list_no_objects))

        result
      end
    end

    context 'when failed' do
      let(:aws_error) { 'SomeError' }

      it 'raises an error' do
        stub_responses(:list_objects_v2, aws_error)

        msg = error_message(aws_error, prefix: key_prefix)
        expect { result }.to raise_error(StatusPage::Storage::Error, msg)
      end
    end
  end

  describe '#list_object_keys' do
    let(:key_prefix) { 'key_prefix/' }

    subject(:result) { client.list_object_keys(key_prefix) }

    context 'when successful' do
      include_context 'list_objects_v2 result'

      it 'returns keys from bucket' do
        expect(result).to eq(Set.new(key_list_1 + key_list_2))
      end
    end

    context 'when exceeds upload limits' do
      include_context 'oversized list_objects_v2 result'

      it 'returns result at max size' do
        expect(result.count).to eq(StatusPage::Storage::MAX_IMAGE_UPLOADS)
      end
    end

    context 'when list_object returns no objects' do
      include_context 'no objects list_objects_v2 result'

      it 'returns an empty set' do
        expect(result).to be_an_instance_of(Set)
        expect(result.empty?).to be(true)
      end
    end

    context 'when failed' do
      let(:aws_error) { 'SomeError' }

      it 'raises an error' do
        stub_responses(:list_objects_v2, aws_error)

        msg = error_message(aws_error, prefix: key_prefix)
        expect { result }.to raise_error(StatusPage::Storage::Error, msg)
      end
    end
  end

  describe 'multipart_upload' do
    let(:key) { '123' }
    let(:file) { Tempfile.new('foo') }
    let(:upload_id) { '123456789' }
    let(:s3_client) { client.instance_variable_get(:@client) }

    subject(:result) { client.multipart_upload(key, file) }

    before do
      file.open
      file.write('hello world')
      file.rewind

      allow(s3_client).to receive(:create_multipart_upload).and_return(
        instance_double(Aws::S3::Types::CompleteMultipartUploadOutput, { to_h: { upload_id: upload_id } })
      )
    end

    after do
      file.close
    end

    context 'when sucessful' do
      before do
        stub_responses(
          :upload_part,
          instance_double(Aws::S3::Types::UploadPartOutput, to_h: {})
        )
      end

      it 'completes' do
        expect(s3_client).to receive(:complete_multipart_upload)

        result
      end

      context 'with more than one part' do
        before do
          stub_const("#{described_class}::MULTIPART_UPLOAD_PART_SIZE", 1.byte)
        end

        it 'completes' do
          # Ensure size limit triggers more than one part upload
          expect(s3_client).to receive(:upload_part).at_least(:twice)
          expect(s3_client).to receive(:complete_multipart_upload)

          result
        end
      end
    end

    context 'when failed' do
      let(:aws_error) { 'SomeError' }

      before do
        stub_responses(:upload_part, aws_error)
      end

      it 'raises an error' do
        expect(s3_client).to receive(:abort_multipart_upload)
        msg = error_message(aws_error, key: key)
        expect { result }.to raise_error(StatusPage::Storage::Error, msg)
      end
    end
  end

  private

  def stub_responses(*args)
    s3_client = client.instance_variable_get(:@client)
    s3_client.stub_responses(*args)
  end

  def error_message(error_class, **args)
    %{Error occured "Aws::S3::Errors::#{error_class}" } \
      "for bucket #{bucket_name.inspect}. Arguments: #{args.inspect}"
  end

  def delete_objects_data(keys)
    objects = keys.map { |key| { key: key } }
    {
      bucket: bucket_name,
      delete: {
        objects: objects
      }
    }
  end

  def list_objects_data(key_list:, next_continuation_token:, is_truncated: )
    contents = key_list.map { |key| Aws::S3::Types::Object.new(key: key) }
    Aws::S3::Types::ListObjectsV2Output.new(
      contents: contents,
      next_continuation_token: next_continuation_token,
      is_truncated: is_truncated
    )
  end
end
