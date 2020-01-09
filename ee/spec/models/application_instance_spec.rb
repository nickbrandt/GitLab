# frozen_string_literal: true

require 'spec_helper'

describe ApplicationInstance do
  it_behaves_like Vulnerable do
    let(:vulnerable) { described_class.new }
  end

  describe '#all_pipelines' do
    it 'returns all CI pipelines for the instance' do
      allow(::Ci::Pipeline).to receive(:all)

      described_class.new.all_pipelines

      expect(::Ci::Pipeline).to have_received(:all)
    end
  end
end
