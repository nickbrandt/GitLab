# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AppJsonLogger do
  subject { described_class.new('/dev/null') }

  let(:hash_message) { { 'message' => 'Message', 'project_id' => '123' } }
  let(:string_message) { 'Information' }

  it 'logs a hash as a JSON' do
    expect(Gitlab::Json.parse(subject.format_message('INFO', Time.current, nil, hash_message))).to include(hash_message)
  end

  it 'logs a string as a JSON' do
    expect(Gitlab::Json.parse(subject.format_message('INFO', Time.current, nil, string_message))).to include('message' => string_message)
  end
end
