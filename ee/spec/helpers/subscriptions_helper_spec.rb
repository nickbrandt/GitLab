# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsHelper do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:raw_plan_data) do
    [
      {
        "name" => "Free Plan",
        "free" => true
      },
      {
        "id" => "bronze_id",
        "name" => "Bronze Plan",
        "free" => false,
        "code" => "bronze",
        "price_per_year" => 48.0
      }
    ]
  end

  before do
    allow(helper).to receive(:params).and_return(plan_id: 'bronze_id', namespace_id: nil)
    allow_next_instance_of(FetchSubscriptionPlansService) do |instance|
      allow(instance).to receive(:execute).and_return(raw_plan_data)
    end
  end

  describe '#subscription_data' do
    let_it_be(:user) { create(:user, setup_for_company: nil, name: 'First Last') }
    let_it_be(:group) { create(:group, name: 'My Namespace') }

    before do
      allow(helper).to receive(:params).and_return(plan_id: 'bronze_id', namespace_id: group.id.to_s)
      allow(helper).to receive(:current_user).and_return(user)
      group.add_owner(user)
    end

    subject { helper.subscription_data }

    it { is_expected.to include(setup_for_company: 'false') }
    it { is_expected.to include(full_name: 'First Last') }
    it { is_expected.to include(plan_data: '[{"id":"bronze_id","code":"bronze","price_per_year":48.0}]') }
    it { is_expected.to include(plan_id: 'bronze_id') }
    it { is_expected.to include(namespace_id: group.id.to_s) }
    it { is_expected.to include(group_data: %Q{[{"id":#{group.id},"name":"My Namespace","users":1}]}) }

    describe 'new_user' do
      where(:referer, :expected_result) do
        'http://example.com/users/sign_up/welcome?foo=bar'             | 'true'
        'http://example.com/users/sign_up/update_registration?foo=bar' | 'true'
        'http://example.com'                                           | 'false'
        nil                                                            | 'false'
      end

      with_them do
        before do
          allow(helper).to receive(:request).and_return(double(referer: referer))
        end

        it { is_expected.to include(new_user: expected_result) }
      end
    end
  end

  describe '#plan_title' do
    subject { helper.plan_title }

    it { is_expected.to eq('Bronze') }

    context 'no plan_id URL parameter present' do
      before do
        allow(helper).to receive(:params).and_return({})
      end

      it { is_expected.to eq(nil) }
    end

    context 'a non-existing plan_id URL parameter present' do
      before do
        allow(helper).to receive(:params).and_return(plan_id: 'xxx')
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#subscription_message' do
    let(:gitlab_subscription) { entity.closest_gitlab_subscription }
    let(:decorated_mock) { double(:decorated_mock) }
    let(:message_mock) { double(:message_mock) }
    let(:user) { double(:user_mock) }

    it 'if it is not Gitlab.com? it returns nil' do
      allow(Gitlab).to receive(:com?).and_return(false)

      expect(helper.subscription_message).to be_nil
    end

    shared_examples 'subscription message' do
      it 'calls Gitlab::ExpiringSubscriptionMessage and SubscriptionPresenter if is Gitlab.com?' do
        allow(Gitlab).to receive(:com?).and_return(true)
        allow(helper).to receive(:signed_in?).and_return(true)
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:can?).with(user, :owner_access, entity).and_return(true)

        expect(SubscriptionPresenter).to receive(:new).with(gitlab_subscription).and_return(decorated_mock)
        expect(::Gitlab::ExpiringSubscriptionMessage).to receive(:new).with(
          subscribable: decorated_mock,
          signed_in: true,
          is_admin: true,
          namespace: namespace
        ).and_return(message_mock)
        expect(message_mock).to receive(:message).and_return('hey yay yay yay')

        expect(helper.subscription_message).to eq('hey yay yay yay')
      end
    end

    context 'when a project is present' do
      let(:entity) { create(:project, namespace: namespace) }
      let(:namespace) { create(:namespace_with_plan) }

      before do
        assign(:project, entity)
      end

      it_behaves_like 'subscription message'
    end

    context 'when a group is present' do
      let(:entity) { create(:group_with_plan) }
      let(:namespace) { entity }

      before do
        assign(:project, nil)
        assign(:group, entity)
      end

      it_behaves_like 'subscription message'
    end
  end

  describe '#decorated_subscription' do
    subject { helper.decorated_subscription }

    shared_examples 'when a subscription exists' do
      let(:gitlab_subscription) { build_stubbed(:gitlab_subscription) }

      it 'returns a decorator' do
        allow(entity).to receive(:closest_gitlab_subscription).and_return(gitlab_subscription)

        expect(subject).to be_a(SubscriptionPresenter)
      end
    end

    context 'when a project exists' do
      let(:entity) { create(:project) }

      before do
        assign(:project, entity)
      end

      it_behaves_like 'when a subscription exists'
    end

    context 'when a group exists' do
      let(:entity) { create(:group) }

      before do
        assign(:group, entity)
      end

      it_behaves_like 'when a subscription exists'
    end

    context 'when no subscription exists' do
      let(:entity) { create(:project) }

      before do
        assign(:project, entity)
      end

      it 'returns a nil object' do
        allow(entity).to receive(:closest_gitlab_subscription).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end
end
