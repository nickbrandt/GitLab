# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elastic::GroupSearchResults do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::GUEST) } }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'user search' do
    subject(:results) { described_class.new(user, nil, nil, group, guest.username, nil) }

    before do
      expect(Gitlab::GroupSearchResults).to receive(:new).and_call_original
    end

    it { expect(results.objects('users')).to eq([guest]) }
    it { expect(results.limited_users_count).to eq(1) }
  end
end
