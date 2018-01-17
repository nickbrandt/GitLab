require 'spec_helper'

describe Geo::UploadDeletedEventStore do
  set(:secondary_node) { create(:geo_node) }
  let(:upload) { create(:upload, checksum: '8710d2c16809c79fee211a9693b64038a8aae99561bc86ce98a9b46b45677fe4') }

  subject(:event_store) { described_class.new(upload) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::UploadDeletedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::UploadDeletedEvent, :count)
      end

      it 'creates a upload deleted event' do
        expect { event_store.create }.to change(Geo::UploadDeletedEvent, :count).by(1)
      end

      it 'tracks upload attributes' do
        event_store.create

        event = Geo::UploadDeletedEvent.last

        expect(event).to have_attributes(
          upload_id: upload.id,
          path: upload.path,
          checksum: upload.checksum,
          model_id: upload.model_id,
          model_type: upload.model_type,
          uploader: upload.uploader
        )
      end

      it 'logs an error message when event creation fail' do
        invalid_upload = create(:upload)
        invalid_upload.update_attribute(:checksum, nil)

        event_store = described_class.new(invalid_upload)

        expected_message = {
          class: "Geo::UploadDeletedEventStore",
          upload_id: invalid_upload.id,
          path: invalid_upload.path,
          model_id: invalid_upload.model_id,
          model_type: invalid_upload.model_type,
          uploader: invalid_upload.uploader,
          message: "Upload deleted event could not be created",
          error: "Validation failed: Checksum can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        event_store.create
      end
    end
  end
end
