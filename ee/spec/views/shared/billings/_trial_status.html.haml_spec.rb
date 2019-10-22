# frozen_string_literal: true

require 'spec_helper'

describe 'shared/billings/_trial_status.html.haml' do
  include ApplicationHelper

  let(:group) { create(:group) }
  let(:gitlab_subscription) { create(:gitlab_subscription, namespace: group) }
  let(:plan) { nil }
  let(:trial_ends_on) { nil }
  let(:trial) { false }

  before do
    gitlab_subscription.update(
      hosted_plan: plan,
      trial_ends_on: trial_ends_on,
      trial: trial
    )
  end

  context 'when not eligible for trial' do
    it 'offers to learn more about plans' do
      render 'shared/billings/trial_status', namespace: group
      expect(rendered).to have_content("Learn more about each plan by visiting our")
    end
  end

  context 'when trial active' do
    let(:plan) { create(:bronze_plan) }
    let(:trial_ends_on) { Date.tomorrow }
    let(:trial) { true }

    it 'displays expiry date' do
      render 'shared/billings/trial_status', namespace: group
      expect(rendered).to have_content("Your GitLab.com trial will expire after #{trial_ends_on}")
    end
  end

  context 'when trial expired' do
    let(:plan) { create(:free_plan) }
    let(:trial_ends_on) { Date.yesterday }

    it 'displays the date is expired' do
      render 'shared/billings/trial_status', namespace: group
      expect(rendered).to have_content("Your GitLab.com trial expired on #{trial_ends_on}")
    end
  end

  context 'when eligible for trial' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    it 'offers a trial' do
      render 'shared/billings/trial_status', namespace: group
      expect(rendered).to have_content("start a free 30-day trial of GitLab.com Gold")
    end
  end
end
