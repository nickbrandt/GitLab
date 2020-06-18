# frozen_string_literal: true

RSpec.shared_examples 'parsing gl_repository identifier' do
  subject { described_class.parse(identifier) }

  it 'returns correct information' do
    expect(subject).to have_attributes(
      repo_type: expected_type,
      container: expected_container
    )
  end
end

RSpec.shared_examples 'illegal gl_identifier' do
  it 'raises an error' do
    expect { described_class.parse(identifier) }.to raise_error(described_class::InvalidIdentifier)
  end
end
