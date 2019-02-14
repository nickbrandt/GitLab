# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Oauth::LoginState do
  let(:salt) { 'b9653b6aa2ff6b54' }
  let(:hmac) { 'd75afcc6faa0fd5133c4512080c42ae579e9d9691bd1731475c287f394a35208' }
  let(:return_to) { 'http://fake-secondary.com:3000/project/test?foo=bar#zoo' }

  before do
    allow(Gitlab::Application.secrets).to receive(:secret_key_base)
      .and_return('712f2a504647cb8aa7b06f2273c1db026dd9d2566acf228cd44f25f7d372c165af72209f34cb9df6623780425ce717884cf0c7f85c1deb108bd45a8cd2c93427')
  end

  describe '.from_state' do
    it 'returns a invalid instance when state is nil' do
      expect(described_class.from_state(nil)).not_to be_valid
    end

    it 'returns a invalid instance when state is empty' do
      expect(described_class.from_state('')).not_to be_valid
    end

    it 'returns a valid instance when state is valid' do
      expect(described_class.from_state("#{salt}:#{hmac}:#{return_to}")).to be_valid
    end
  end

  describe '#valid?' do
    it 'returns false when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect(subject.valid?).to eq false
    end

    it 'returns false when return_to is empty' do
      subject = described_class.new(return_to: '')

      expect(subject.valid?).to eq false
    end

    it 'returns false when hmac is nil' do
      subject = described_class.new(return_to: return_to, salt: salt, hmac: nil)

      expect(subject.valid?).to eq false
    end

    it 'returns false when hmac is empty' do
      subject = described_class.new(return_to: return_to, salt: salt, hmac: '')

      expect(subject.valid?).to eq false
    end

    it 'returns false when salt not match' do
      subject = described_class.new(return_to: return_to, salt: 'salt', hmac: hmac)

      expect(subject.valid?).to eq(false)
    end

    it 'returns false when hmac does not match' do
      subject = described_class.new(return_to: return_to, salt: salt, hmac: 'hmac')

      expect(subject.valid?).to eq(false)
    end

    it 'returns true when hmac matches' do
      subject = described_class.new(return_to: return_to, salt: salt, hmac: hmac)

      expect(subject.valid?).to eq(true)
    end
  end

  describe '#encode' do
    it 'does not raise an error when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect { subject.encode }.not_to raise_error
    end

    it 'returns a string with salt, hmac, and return_to colon separated' do
      subject = described_class.new(return_to: return_to)

      salt, hmac, return_to = subject.encode.split(':', 3)

      expect(salt).not_to be_blank
      expect(hmac).not_to be_blank
      expect(return_to).to eq return_to
    end
  end

  describe '#return_to' do
    it 'returns nil when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect(subject.return_to).to be_nil
    end

    it 'returns an empty string when return_to is empty' do
      subject = described_class.new(return_to: '')

      expect(subject.return_to).to eq('')
    end

    it 'returns the full path of the return_to URL' do
      subject = described_class.new(return_to: return_to)

      expect(subject.return_to).to eq('/project/test?foo=bar#zoo')
    end
  end
end
