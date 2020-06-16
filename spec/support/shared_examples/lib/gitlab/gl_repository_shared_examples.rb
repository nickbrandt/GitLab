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
  subject do
    described_class.parse(identifier).tap do |ident|
      ident.repo_type
      ident.container
    end
  end

  it 'raises an error' do
    expect { subject }.to raise_error(described_class::IllegalIdentifier)
  end
end
