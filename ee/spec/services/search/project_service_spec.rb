require 'spec_helper'

describe Search::ProjectService do
  it_behaves_like 'EE search service shared examples', ::Gitlab::ProjectSearchResults, ::Gitlab::Elastic::ProjectSearchResults do
    let(:user) { scope.owner }
    let(:scope) { create(:project) }
    let(:service) { described_class.new(scope, user, search: '*') }
  end
end
