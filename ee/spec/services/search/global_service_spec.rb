require 'spec_helper'

describe Search::GlobalService do
  let(:user) { create(:user) }

  it_behaves_like 'EE search service shared examples', ::Gitlab::SearchResults, ::Gitlab::Elastic::SearchResults do
    let(:scope) { nil }
    let(:service) { described_class.new(user, search: '*') }
  end
end
