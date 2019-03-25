require 'spec_helper'

describe Search::ProjectService do
  let(:project) { create(:project) }
  let(:user) { project.owner }

  describe 'elasticsearch' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    subject(:results) { described_class.new(project, user, search: '*').execute }

    it { is_expected.to be_a(::Gitlab::Elastic::ProjectSearchResults) }
  end
end
