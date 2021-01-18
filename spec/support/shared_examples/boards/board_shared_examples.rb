# frozen_string_literal: true

RSpec.shared_examples '#board_type' do |expected_type|
  it "is of type #{expected_type}" do
    expect(subject.board_type).to eq expected_type
  end
end
