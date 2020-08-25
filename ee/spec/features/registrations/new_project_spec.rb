# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project screen', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let(:in_subscription_flow) { false }

  before do
    gitlab_sign_in(user)
    namespace.add_owner(user)
    allow_any_instance_of(EE::RegistrationsHelper).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
    stub_experiment_for_user(onboarding_issues: true)
    visit new_users_sign_up_project_path(namespace_id: namespace.id)
  end

  subject { page }

  it 'shows the progress bar with the correct steps' do
    expect(subject).to have_content('Create/import your first project')
    expect(subject).to have_content('Your profile Your GitLab group Your first project')
  end

  context 'when in the subscription flow' do
    let(:in_subscription_flow) { true }

    it { is_expected.to have_content('Your profile Checkout Your GitLab group Your first project') }
  end
end
