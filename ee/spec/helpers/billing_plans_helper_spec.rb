# frozen_string_literal: true

require 'spec_helper'

describe BillingPlansHelper do
  describe '#current_plan?' do
    it 'returns true when current_plan' do
      plan = Hashie::Mash.new(purchase_link: { action: 'current_plan' })

      expect(helper.current_plan?(plan)).to be_truthy
    end

    it 'return false when not current_plan' do
      plan = Hashie::Mash.new(purchase_link: { action: 'upgrade' })

      expect(helper.current_plan?(plan)).to be_falsy
    end
  end

  describe '#subscription_plan_data_attributes' do
    let(:customer_portal_url) { "https://customers.gitlab.com/subscriptions" }

    let(:group) { build(:group) }
    let(:plan) do
      Hashie::Mash.new(id: 'external-paid-plan-hash-code')
    end

    context 'when group and plan with ID present' do
      it 'returns data attributes' do
        upgrade_href =
          "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/upgrade/#{plan.id}"

        expect(helper.subscription_plan_data_attributes(group, plan))
          .to eq(namespace_id: group.id,
                 namespace_name: group.name,
                 plan_upgrade_href: upgrade_href,
                 customer_portal_url: customer_portal_url)
      end
    end

    context 'when group not present' do
      let(:group) { nil }

      it 'returns empty data attributes' do
        expect(helper.subscription_plan_data_attributes(group, plan)).to eq({})
      end
    end

    context 'when plan with ID not present' do
      let(:plan) { Hashie::Mash.new(id: nil) }

      it 'returns data attributes without upgrade href' do
        expect(helper.subscription_plan_data_attributes(group, plan))
          .to eq(namespace_id: group.id,
                 namespace_name: group.name,
                 customer_portal_url: customer_portal_url,
                 plan_upgrade_href: nil)
      end
    end
  end

  describe '#use_new_purchase_flow?' do
    using RSpec::Parameterized::TableSyntax

    where free_group_new_purchase: [true, false],
          type: ['Group', nil],
          plan: Plan.all_plans

    with_them do
      let_it_be(:user) { create(:user) }
      let(:namespace) do
        create :namespace, type: type,
               gitlab_subscription: create(:gitlab_subscription, hosted_plan: create("#{plan}_plan".to_sym))
      end

      before do
        allow(helper).to receive(:current_user).and_return(user)
        stub_feature_flags free_group_new_purchase_flow: free_group_new_purchase
      end

      subject { helper.use_new_purchase_flow?(namespace) }

      it do
        result = free_group_new_purchase && type == 'Group' && plan == Plan::FREE

        is_expected.to be(result)
      end
    end
  end
end
