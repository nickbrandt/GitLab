# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LogTimestampFormatter do
  subject { described_class.new }

  let(:formatted_timestamp) { Time.current.utc.iso8601(3) }

  it 'logs the timestamp in UTC and ISO8601.3 format' do
    Timecop.freeze(Time.current) do
      expect(subject.call('', Time.current, '', '')).to include formatted_timestamp
    end
  end
end
