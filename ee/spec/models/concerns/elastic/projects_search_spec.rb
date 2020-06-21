# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProjectsSearch do
  subject do
    Class.new do
      include Elastic::ProjectsSearch

      def id
        1
      end

      def es_id
        1
      end
    end.new
  end

  describe '#maintain_elasticsearch_create' do
    it 'calls process_async' do
      expect(::Gitlab::Elastic::BulkIndexer::InitialProcessor).to receive(:process_async).and_return(true)

      subject.maintain_elasticsearch_create
    end
  end

  describe '#maintain_elasticsearch_update' do
    it 'calls process_async' do
      expect(::Gitlab::Elastic::BulkIndexer::IncrementalProcessor).to receive(:process_async).and_return(true)

      subject.maintain_elasticsearch_update
    end
  end

  describe '#maintain_elasticsearch_destroy' do
    it 'calls delete worker' do
      expect(ElasticDeleteProjectWorker).to receive(:perform_async)

      subject.maintain_elasticsearch_destroy
    end
  end
end
