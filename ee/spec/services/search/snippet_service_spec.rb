# frozen_string_literal: true

require 'spec_helper'

describe Search::SnippetService do
  it_behaves_like 'EE search service shared examples', ::Gitlab::SnippetSearchResults, ::Gitlab::Elastic::SnippetSearchResults do
    let(:user) { create(:user) }
    let(:scope) { nil }
    let(:service) { described_class.new(user, params) }
  end
end
