# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Provisioners::Aws do
  describe 'settings from configuration' do
    it { is_expected.to delegate_method(:account_id).to(:config).allow_nil }
    it { is_expected.to delegate_method(:access_key_id).to(:config).allow_nil }
    it { is_expected.to delegate_method(:secret_access_key).to(:config).allow_nil }

    shared_examples 'setting is missing' do
      before do
        allow(Gitlab.config).to receive(:kubernetes).and_raise(Settingslogic::MissingSetting)
      end

      it { is_expected.to be_nil }
    end

    describe '#account_id' do
      subject { described_class.new.account_id }

      include_examples 'setting is missing'
    end

    describe '#access_key_id' do
      subject { described_class.new.access_key_id }

      include_examples 'setting is missing'
    end

    describe '#secret_access_key' do
      subject { described_class.new.secret_access_key }

      include_examples 'setting is missing'
    end
  end
end
