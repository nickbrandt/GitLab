# frozen_string_literal: true

require 'spec_helper'

describe Geo::PackageFileReplicator do
  include EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:model_record) { create(:package_file, :npm) }

  subject { described_class.new(model_record: model_record) }

  before do
    stub_current_geo_node(primary)
  end

  describe '#publish_created_event' do
    it "creates a Geo::Event" do
      expect do
        subject.publish_created_event
      end.to change { ::Geo::Event.count }.by(1)

      expect(::Geo::Event.last.attributes).to include("replicable_name" => "package_file", "event_name" => "created", "payload" => { "model_record_id" => model_record.id })
    end
  end

  describe '#consume_created_event' do
    it 'invokes Geo::BlobDownloadService' do
      service = double(:service)
      expect(service).to receive(:execute)
      expect(::Geo::BlobDownloadService).to receive(:new).with(replicator: subject).and_return(service)

      subject.consume_created_event
    end
  end
end
