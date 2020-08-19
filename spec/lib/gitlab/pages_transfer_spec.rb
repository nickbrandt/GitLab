# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PagesTransfer do
  describe '#async' do
    let(:async) { subject.async }

    context 'when receiving an allowed method' do
      it 'schedules a PagesTransferWorker', :aggregate_failures do
        described_class::Async::METHODS.each do |meth|
          expect(PagesTransferWorker)
            .to receive(:perform_async).with(meth, %w[foo bar])

          async.public_send(meth, 'foo', 'bar')
        end
      end
    end

    context 'when receiving a private method' do
      it 'raises NoMethodError' do
        expect { async.move('foo', 'bar') }.to raise_error(NoMethodError)
      end
    end

    context 'when receiving a non-existent method' do
      it 'raises NoMethodError' do
        expect { async.foo('bar') }.to raise_error(NoMethodError)
      end
    end
  end
end
