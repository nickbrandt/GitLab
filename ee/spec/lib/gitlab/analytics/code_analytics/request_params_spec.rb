# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CodeAnalytics::RequestParams do
  let(:params) { { file_count: 5 } }

  subject { described_class.new(params) }

  it 'is valid' do
    expect(subject).to be_valid
  end

  context 'when `file_count` is invalid' do
    before do
      params[:file_count] = -1
    end

    it 'is invalid' do
      expect(subject).not_to be_valid
      expect(subject.errors[:file_count]).not_to be_empty
    end
  end
end
