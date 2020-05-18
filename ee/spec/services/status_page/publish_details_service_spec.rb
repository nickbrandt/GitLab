# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishDetailsService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:user_notes) { [] }
  let(:incident_id) { 1 }
  let(:issue) { instance_double(Issue, notes: user_notes, description: 'Incident Occuring', iid: incident_id) }
  let(:key) { StatusPage::Storage.details_path(incident_id) }
  let(:content) { { id: incident_id } }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issue, user_notes) }

  describe '#execute' do
    before do
      allow(serializer).to receive(:represent_details).with(issue, user_notes)
        .and_return(content)
    end

    include_examples 'publish incidents'

    context 'when serialized content is missing id' do
      let(:content) { { other_id: incident_id } }

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq('Missing object key')
      end
    end

    context 'publishes attachments' do
      it 'sends attachements to s3' do
        allow(storage_client).to receive(:upload_object)
        allow(storage_client).to receive(:list_object_keys).and_return([])

        expect_next_instance_of(StatusPage::PublishAttachmentsService) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end
  end
end
