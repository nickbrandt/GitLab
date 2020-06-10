# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database config initializer for GitLab EE' do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  before do
    stub_geo_database_config(pool_size: 1)
  end

  context "when using multi-threaded runtime" do
    let(:max_threads) { 8 }

    before do
      allow(Gitlab::Runtime).to receive(:multi_threaded?).and_return(true)
      allow(Gitlab::Runtime).to receive(:max_threads).and_return(max_threads)
      allow(ActiveRecord::Base).to receive(:establish_connection)

      expect(Geo::TrackingBase).to receive(:establish_connection)
    end

    context "and the runtime is Sidekiq" do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      it "sets Geo DB connection pool size to the max number of worker threads" do
        expect { subject }.to change { Rails.configuration.geo_database['pool'] }.from(1).to(max_threads)
      end
    end
  end

  context "when using single-threaded runtime" do
    it "does nothing" do
      expect { subject }.not_to change { Rails.configuration.geo_database['pool'] }
    end
  end

  def stub_geo_database_config(pool_size:)
    config = {
      'adapter' => 'postgresql',
      'host' => 'db.host.com',
      'pool' => pool_size
    }.compact

    allow(Rails.configuration).to receive(:geo_database).and_return(config)
  end
end
