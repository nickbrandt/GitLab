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

  private

  def stub_responses(*args)
    s3_client = client.instance_variable_get(:@client)
    s3_client.stub_responses(*args)
  end

  def error_message(error_class, **args)
    %{Error occured "Aws::S3::Errors::#{error_class}" } \
      "for bucket #{bucket_name.inspect}. Arguments: #{args.inspect}"
  end
end
