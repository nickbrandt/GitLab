# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishListService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:storage_client) { instance_double(StatusPage::Storage::S3Client) }
  let(:serializer) { instance_double(StatusPage::IncidentSerializer) }
  let(:issues) { [instance_double(Issue)] }
  let(:key) { StatusPage::Storage.list_path }
  let(:content) { [{ some: :content }] }
  let(:content_json) { content.to_json }

  let(:service) do
    described_class.new(
      project: project, storage_client: storage_client, serializer: serializer
    )
  end

  subject(:result) { service.execute(issues) }

  describe '#execute' do
    context 'when license is available' do
      before do
        allow(serializer).to receive(:represent_list).with(issues)
          .and_return(content)
      end

      include_examples 'publish incidents'
    end
  end
end
