# frozen_string_literal: true

require "spec_helper"

describe ServiceDeskEmailReceiverWorker, :mailer do
  describe '#perform' do
    let(:worker) { described_class.new }
    let(:email) { 'foo' }

    context 'when service_desk_email config is enabled' do
      before do
        allow(worker).to receive(:config)
          .and_return(double(enabled: true, address: 'foo'))
      end

      context 'when service_desk_email feature is enabled' do
        before do
          stub_feature_flags(service_desk_email: true)
        end

        it 'does not ignore the email' do
          expect { worker.perform(email) }.to raise_error(NotImplementedError)
        end
      end

      context 'when service_desk_email feature is disabled' do
        before do
          stub_feature_flags(service_desk_email: false)
        end

        it 'ignores the email' do
          expect { worker.perform(email) }.not_to raise_error(NotImplementedError)
        end
      end
    end

    context 'when service_desk_email config is disabled' do
      before do
        allow(worker).to receive(:config)
          .and_return(double(enabled: false, address: 'foo'))
      end

      it 'ignores the email' do
        expect { worker.perform(email) }.not_to raise_error(NotImplementedError)
      end
    end
  end
end
