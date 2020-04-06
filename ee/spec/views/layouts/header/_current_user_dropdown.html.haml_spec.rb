# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/header/_current_user_dropdown' do
  let_it_be(:user) { create(:user) }
  let(:need_minutes) { true }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:show_buy_ci_minutes?).and_return(need_minutes)

    render
  end

  subject { rendered }

  context 'when ci minutes need bought' do
    it 'has "Buy CI minutes" link with correct data properties', :aggregate_failures do
      expect(subject).to have_selector('[data-track-event="click_buy_ci_minutes"]')
      expect(subject).to have_selector("[data-track-label='#{user.namespace.actual_plan_name}']")
      expect(subject).to have_selector('[data-track-property="user_dropdown"]')
      expect(subject).to have_link('Buy CI minutes')
    end
  end

  context 'when ci minutes do not need bought' do
    let(:need_minutes) { false }

    it 'has no "Buy CI minutes" link' do
      expect(subject).not_to have_link('Buy CI minutes')
    end
  end
end
