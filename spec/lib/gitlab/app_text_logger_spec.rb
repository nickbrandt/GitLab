# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppTextLogger do
  subject { described_class.new('/dev/null') }

  let(:hash_message) { { message: 'Message', project_id: 123 } }
  let(:string_message) { 'Information' }

  it 'logs a hash as string' do
    expect(subject.format_message('INFO', Time.current, nil, hash_message )).to include(hash_message.to_s)
  end

  it 'logs a string unchanged' do
    expect(subject.format_message('INFO', Time.current, nil, string_message)).to include(string_message)
  end

  it 'logs time in UTC with ISO8601.3 standard' do
    Timecop.freeze do
      expect(subject.format_message('INFO', Time.current, nil, string_message))
        .to include(Time.current.utc.iso8601(3))
    end
  end
end
