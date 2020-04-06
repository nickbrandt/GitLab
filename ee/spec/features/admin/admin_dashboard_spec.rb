# frozen_string_literal: true

require 'spec_helper'

describe 'Admin Dashboard' do
  describe 'Users statistic' do
    before do
      project1 = create(:project_empty_repo)
      project1.add_reporter(create(:user))

      project2 = create(:project_empty_repo)
      project2.add_developer(create(:user))

      # Add same user as Reporter and Developer to different projects
      # and expect it to be counted once for the stats
      user = create(:user)
      project1.add_reporter(user)
      project2.add_developer(user)

      create(:user, user_type: :support_bot)
      create(:user, user_type: :alert_bot)

      sign_in(create(:admin))
    end

    describe 'Roles stats' do
      context 'for tooltip' do
        let(:create_guest) { false }

        before do
          allow(License).to receive(:current).and_return(license)

          if create_guest
            project = create(:project_empty_repo)
            guest_user = create(:user)
            project.add_guest(guest_user)
          end

          visit admin_dashboard_stats_path
        end

        context 'when license is empty' do
          let(:license) { nil }

          it { expect(page).not_to have_css('span.has-tooltip') }
        end

        context 'when license is on a plan Ultimate' do
          let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

          context 'when guests do not exist' do
            it { expect(page).not_to have_css('span.has-tooltip') }
          end

          context 'when guests exist' do
            let(:create_guest) { true }

            it { expect(page).to have_css('span.has-tooltip') }
          end
        end

        context 'when license is on a plan other than Ultimate' do
          let(:license) { create(:license, plan: License::PREMIUM_PLAN) }

          it { expect(page).not_to have_css('span.has-tooltip') }
        end
      end

      it 'shows correct amounts of users per role', :aggregate_failures do
        visit admin_dashboard_stats_path

        expect(page).to have_content('Users with highest role developer 2')
        expect(page).to have_content('Users with highest role reporter 1')
        expect(page).to have_content('Bots 2')
      end
    end
  end
end
