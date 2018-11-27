# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database do
  describe '.read_only?' do
    context 'with Geo enabled' do
      before do
        allow(Gitlab::Geo).to receive(:enabled?) { true }
        allow(Gitlab::Geo).to receive(:current_node) { geo_node }
      end

      context 'is Geo secondary node' do
        let(:geo_node) { create(:geo_node) }

        it 'returns true' do
          expect(described_class.read_only?).to be_truthy
        end
      end

      context 'is Geo primary node' do
        let(:geo_node) { create(:geo_node, :primary) }

        it 'returns false when is Geo primary node' do
          expect(described_class.read_only?).to be_falsey
        end
      end
    end

    context 'with Geo disabled' do
      it 'returns false' do
        expect(described_class.read_only?).to be_falsey
      end
    end
  end

  describe '.healthy?' do
    it 'returns true when using MySQL' do
      allow(described_class).to receive(:postgresql?).and_return(false)

      expect(described_class.healthy?).to be_truthy
    end

    context 'when using PostgreSQL' do
      before do
        allow(described_class).to receive(:postgresql?).and_return(true)
      end

      it 'returns true when replication lag is not too great' do
        allow(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(false)

        expect(described_class.healthy?).to be_truthy
      end

      it 'returns false when replication lag is too great' do
        allow(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(true)

        expect(described_class.healthy?).to be_falsey
      end
    end
  end

  describe '.disable_prepared_statements' do
    it 'disables prepared statements' do
      config = {}

      expect(ActiveRecord::Base.configurations).to receive(:[])
        .with(Rails.env)
        .and_return(config)

      expect(ActiveRecord::Base).to receive(:establish_connection)
        .with({ 'prepared_statements' => false })

      described_class.disable_prepared_statements

      expect(config['prepared_statements']).to eq(false)
    end
  end
end
