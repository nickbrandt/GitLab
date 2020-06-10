# frozen_string_literal: true

require 'spec_helper'

# We don't want to interact with Elasticsearch in GitLab FOSS so we test
# this in ee/ only. The code exists in FOSS and won't do anything.

RSpec.describe Peek::Views::Elasticsearch, :elastic, :request_store do
  before do
    allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    ensure_elasticsearch_index!
  end

  describe '#results' do
    let(:results) { described_class.new.results }

    it 'includes performance details' do
      expect(results[:calls]).to be > 0
      expect(results[:duration]).to be_kind_of(String)
      expect(results[:details].last[:method]).to eq("POST")
      expect(results[:details].last[:path]).to eq("gitlab-test/_refresh")
    end
  end
end
