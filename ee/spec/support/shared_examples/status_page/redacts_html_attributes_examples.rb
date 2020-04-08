# frozen_string_literal: true

# This shared_example requires the following variables:
# - redacted_value: The redacted value
RSpec.shared_examples 'redacts HTML attributes' do
  let(:confidential) { create(:issue, :confidential) }
  let(:reference) { confidential.to_reference(full: true) }

  before do
    object.update!(field => reference)
  end

  it 'redacts link anchor and HTML data attributes' do
    aggregate_failures do
      expect(redacted_value).to include(reference)
      expect(redacted_value).not_to include(confidential.title)
      expect(redacted_value).not_to include('<a ')
    end
  end
end
