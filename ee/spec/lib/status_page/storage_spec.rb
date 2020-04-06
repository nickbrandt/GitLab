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
end
