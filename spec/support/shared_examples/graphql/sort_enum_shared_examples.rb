# frozen_string_literal: true

RSpec.shared_examples 'common sort values' do
  it 'exposes all the existing common sort values' do
    expect(described_class.values.keys).to include(*%w[UPDATED_DESC UPDATED_ASC CREATED_DESC CREATED_ASC])
  end
end
