# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_current_user_dropdown' do
  let_it_be(:user) { create(:user) }

  describe 'Buy Pipeline Minutes link in user dropdown' do
    let(:need_minutes) { true }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:show_upgrade_link?).and_return(false)
      allow(view).to receive(:show_buy_pipeline_minutes?).and_return(need_minutes)

      render
    end

    subject { rendered }

    context 'when pipeline minutes need bought' do
      it 'has "Buy Pipeline minutes" link with correct data properties', :aggregate_failures do
        expect(subject).to have_selector('[data-track-event="click_buy_ci_minutes"]')
        expect(subject).to have_selector("[data-track-label='#{user.namespace.actual_plan_name}']")
        expect(subject).to have_selector('[data-track-property="user_dropdown"]')
        expect(subject).to have_link('Buy Pipeline minutes')
      end
    end

    context 'when ci minutes do not need bought' do
      let(:need_minutes) { false }

      it 'has no "Buy Pipeline minutes" link' do
        expect(subject).not_to have_link('Buy Pipeline minutes')
      end
    end
  end

  describe 'Upgrade link in user dropdown' do
    let(:on_upgradeable_plan) { true }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:show_buy_pipeline_minutes?).and_return(false)
      allow(view).to receive(:show_upgrade_link?).and_return(on_upgradeable_plan)

      render
    end

    subject { rendered }

    context 'when user is on an upgradeable plan' do
      it 'displays the Upgrade link' do
        expect(subject).to have_link('Upgrade')
      end
    end

    context 'when user is not on an upgradeable plan' do
      let(:on_upgradeable_plan) { false }

      it 'does not display the Upgrade link' do
        expect(subject).not_to have_link('Upgrade')
      end
    end
  end
end
