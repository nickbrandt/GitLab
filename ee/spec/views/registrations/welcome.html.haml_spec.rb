# frozen_string_literal: true

require 'spec_helper'

describe 'registrations/welcome' do
  let_it_be(:user) { User.new }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_paid_signup_flow?).and_return(in_paid_signup_flow)

    render
  end

  subject { rendered }

  context 'in paid_signup_flow' do
    let(:in_paid_signup_flow) { true }

    it { is_expected.to have_button('Continue') }
    it { is_expected.to have_selector('#progress-bar') }
  end

  context 'not in paid_signup_flow' do
    let(:in_paid_signup_flow) { false }

    it { is_expected.to have_button('Get started!') }
    it { is_expected.not_to have_selector('#progress-bar') }
  end
end
