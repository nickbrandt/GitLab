require 'spec_helper'

describe 'Groups > Billing', :js do
  include StubRequests

  let!(:user)        { create(:user) }
  let!(:group)       { create(:group) }
  let!(:bronze_plan) { create(:bronze_plan) }

  before do
    stub_full_request("https://customers.gitlab.com/gitlab_plans?plan=#{plan}")
      .to_return(status: 200, body: File.new(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json')))

    stub_application_setting(check_namespace_plan: true)

    group.add_owner(user)
    sign_in(user)
  end

  context 'with a free plan' do
    let(:plan) { 'free' }

    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: nil, seats: 15)
    end

    it 'shows the proper title for the plan' do
      visit group_billings_path(group)

      expect(page).to have_content("#{group.name} is currently on the Free plan")
    end
  end

  context 'with a paid plan' do
    let(:plan) { 'bronze' }

    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: bronze_plan, seats: 15)
    end

    it 'shows the proper title for the plan' do
      visit group_billings_path(group)

      expect(page).to have_content("#{group.name} is currently on the Bronze plan")
    end
  end

  context 'with a legacy paid plan' do
    let(:plan) { 'bronze' }

    before do
      group.update_attribute(:plan, bronze_plan)
    end

    it 'shows the proper title for the plan' do
      visit group_billings_path(group)

      expect(page).to have_content("#{group.name} is currently on the Bronze plan")
    end
  end
end
