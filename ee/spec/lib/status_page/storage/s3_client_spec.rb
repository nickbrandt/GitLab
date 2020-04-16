# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Storage::S3Client, :aws_s3 do
  let(:region) { 'eu-west-1' }
  let(:bucket_name) { 'bucket_name' }
  let(:access_key_id) { 'key_id' }
  let(:secret_access_key) { 'secret' }

  let(:client) do
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

    subject(:result) { client.recursive_delete(key_prefix) }

    context 'when successful' do
      let(:key_list_1) { ['key_prefix/1', 'key_prefix/2'] }
      let(:key_list_2) { ['key_prefix/3'] }

      before do
        # AWS s3 client responses for list_objects is paginated
        # stub_responses allows multiple responses as arguments and they will be returned in sequence
        stub_responses(
          :list_objects_v2,
          list_objects_data(key_list: key_list_1, next_continuation_token: '12345', is_truncated: true),
          list_objects_data(key_list: key_list_2, next_continuation_token: nil, is_truncated: false)
        )
      end

      it 'sends keys for batch delete' do
        aws_client = client.send('client')
        expect(aws_client).to receive(:delete_objects).with(delete_objects_data(key_list_1))
        expect(aws_client).to receive(:delete_objects).with(delete_objects_data(key_list_2))

        result
      end

      it 'returns true' do
        expect(result).to eq(true)
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
