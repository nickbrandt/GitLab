# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elastic::GroupSearchResults do
  subject(:results) { described_class.new(user, nil, nil, group, query, nil) }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::GUEST) } }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'user search' do
    let(:query) { guest.username }

    before do
      expect(Gitlab::GroupSearchResults).to receive(:new).and_call_original
    end

    it { expect(results.objects('users')).to eq([guest]) }
    it { expect(results.limited_users_count).to eq(1) }

    describe 'pagination' do
      let(:query) {}

      let_it_be(:user2) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::REPORTER) } }

      it 'returns the correct page of results' do
        expect(results.objects('users', page: 1, per_page: 1)).to eq([user2])
        expect(results.objects('users', page: 2, per_page: 1)).to eq([guest])
      end

      it 'returns the correct number of results for one page' do
        expect(results.objects('users', page: 1, per_page: 2).count).to eq(2)
      end
    end
  end
end
