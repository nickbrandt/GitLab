# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Storage do
  describe '.details_path' do
    subject { described_class.details_path(123) }

    it { is_expected.to eq('data/incident/123.json') }
  end

  describe '.list_path' do
    subject { described_class.list_path }

    it { is_expected.to eq('data/list.json') }
  end

  describe '.upload_path' do
    subject { described_class.upload_path(2, '50b7a196557cf72a98e86a7ab4b1ac3b', 'screenshot.png') }

    it { is_expected.to eq('data/incident/2/50b7a196557cf72a98e86a7ab4b1ac3b/screenshot.png') }
  end

  describe '.uploads_path' do
    subject { described_class.uploads_path(2) }

    it { is_expected.to eq('data/incident/2/') }
  end
end
