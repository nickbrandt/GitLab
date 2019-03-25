require 'spec_helper'

describe Search::SnippetService do
  let(:user) { create(:user) }

  describe 'elasticsearch' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    subject(:results) { described_class.new(user, search: '*').execute }

    it { is_expected.to be_a(::Gitlab::Elastic::SnippetSearchResults) }
  end
end
