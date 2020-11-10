# frozen_string_literal: true

# This should be included on any Replicator which implements verification.
#
RSpec.shared_examples 'a verifiable replicator' do
  include EE::GeoHelpers

  describe '.verification_enabled?' do
    context 'when replication is enabled' do
      before do
        expect(described_class).to receive(:enabled?).and_return(true)
      end

      context 'when the verification feature flag is enabled' do
        it 'returns true' do
          allow(described_class).to receive(:verification_feature_flag_enabled?).and_return(true)

          expect(described_class.verification_enabled?).to be_truthy
        end
      end

      context 'when geo_framework_verification feature flag is disabled' do
        it 'returns false' do
          allow(described_class).to receive(:verification_feature_flag_enabled?).and_return(false)

          expect(described_class.verification_enabled?).to be_falsey
        end
      end
    end

    context 'when replication is disabled' do
      before do
        expect(described_class).to receive(:enabled?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.verification_enabled?).to be_falsey
      end
    end
  end

  describe '.checksummed_count' do
    context 'when verification is enabled' do
      before do
        allow(described_class).to receive(:verification_enabled?).and_return(true)
      end

      it 'returns the number of available replicables where verification succeeded' do
        model_record.verification_started!
        model_record.verification_succeeded_with_checksum!('some checksum', Time.current)

        expect(described_class.checksummed_count).to eq(1)
      end

      it 'excludes other verification states' do
        model_record.verification_started!

        expect(described_class.checksummed_count).to eq(0)

        model_record.verification_failed_with_message!('some error message')

        expect(described_class.checksummed_count).to eq(0)

        model_record.verification_pending!

        expect(described_class.checksummed_count).to eq(0)
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.checksummed_count).to be_nil
      end
    end
  end

  describe '.checksum_failed_count' do
    context 'when verification is enabled' do
      before do
        allow(described_class).to receive(:verification_enabled?).and_return(true)
      end

      it 'returns the number of available replicables where verification failed' do
        model_record.verification_started!
        model_record.verification_failed_with_message!('some error message')

        expect(described_class.checksum_failed_count).to eq(1)
      end

      it 'excludes other verification states' do
        model_record.verification_started!

        expect(described_class.checksum_failed_count).to eq(0)

        model_record.verification_succeeded_with_checksum!('foo', Time.current)

        expect(described_class.checksum_failed_count).to eq(0)

        model_record.verification_pending!

        expect(described_class.checksum_failed_count).to eq(0)
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.checksum_failed_count).to be_nil
      end
    end
  end

  describe '#after_verifiable_update' do
    it 'calls verify_async if needed' do
      expect(replicator).to receive(:verify_async)
      expect(replicator).to receive(:needs_checksum?).and_return(true)

      replicator.after_verifiable_update
    end
  end

  describe '#verify' do
    before do
      model_record.save!
    end

    it 'calculates the checksum' do
      expect(model_record).to receive(:calculate_checksum).and_return('abc123')

      replicator.verify

      expect(model_record.reload.verification_checksum).to eq('abc123')
      expect(model_record.verified_at).not_to be_nil
    end

    it 'saves the error message and increments retry counter' do
      allow(model_record).to receive(:calculate_checksum) do
        raise StandardError.new('Failure to calculate checksum')
      end

      replicator.verify

      expect(model_record.reload.verification_failure).to eq 'Failure to calculate checksum'
      expect(model_record.verification_retry_count).to be 1
    end
  end
end
