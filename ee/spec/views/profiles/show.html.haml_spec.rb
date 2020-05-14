# frozen_string_literal: true

require 'spec_helper'

describe 'profiles/show' do
  context 'gitlab.com organization field' do
    let(:user) { create(:user) }

    before do
      assign(:user, user)
      allow(controller).to receive(:current_user).and_return(user)
      allow(view).to receive(:experiment_enabled?)
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when `:gitlab_employee_badge` feature flag is enabled' do
      context 'and when user is a gitlab team member' do
        include_context 'gitlab team member'

        it 'displays the organization field as `readonly` with a `value` of `GitLab`' do
          render

          expect(rendered).to have_selector('#user_organization[readonly][value="GitLab"]')
        end
      end

      context 'and when a user is not a gitlab team member' do
        it 'displays an editable organization field' do
          render

          expect(rendered).to have_selector('#user_organization:not([readonly]):not([value="GitLab"])')
        end
      end
    end

    context 'when `:gitlab_employee_badge` feature flag is disabled' do
      before do
        stub_feature_flags(gitlab_employee_badge: false)
      end

      context 'and when a user is a gitlab team member' do
        include_context 'gitlab team member'

        it 'displays an editable organization field' do
          render

          expect(rendered).to have_selector('#user_organization:not([readonly]):not([value="GitLab"])')
        end
      end
    end
  end
end
