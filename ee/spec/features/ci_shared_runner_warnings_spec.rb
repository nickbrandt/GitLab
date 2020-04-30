# frozen_string_literal: true

require 'spec_helper'

describe 'CI shared runner limits' do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  shared_examples 'threshold breached' do
    before do
      group.update(shared_runners_minutes_limit: 20)
    end

    it 'displays a warning message on pipelines page' do
      visit project_pipelines_path(project)

      expect_quota_exceeded_alert(message)
    end

    it 'displays a warning message on project homepage' do
      visit project_path(project)

      expect_quota_exceeded_alert(message)
    end
  end

  context 'when project member' do
    before do
      group.add_developer(user)
    end

    context 'without limit' do
      it 'does not display a warning message on project homepage' do
        visit project_path(project)

        expect_no_quota_exceeded_alert
      end

      it 'does not display a warning message on pipelines page' do
        visit project_pipelines_path(project)

        expect_no_quota_exceeded_alert
      end
    end

    context 'when limit is defined' do
      context 'when usage has reached a warning level', :js do
        it_behaves_like 'threshold breached' do
          let(:message) do
            "Group #{group.name} has 30% or less Shared Runner Pipeline minutes remaining. " \
            "Once it runs out, no new jobs or pipelines in its projects will run."
          end

          before do
            allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(4)
          end
        end
      end

      context 'when usage has reached a danger level', :js do
        it_behaves_like 'threshold breached' do
          let(:message) do
            "Group #{group.name} has 5% or less Shared Runner Pipeline minutes remaining. " \
            "Once it runs out, no new jobs or pipelines in its projects will run."
          end

          before do
            allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(1)
          end
        end
      end

      context 'when limit is exceeded', :js do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:message) do
          "Group #{group.name} has exceeded its pipeline minutes quota. " \
          "Unless you buy additional pipeline minutes, no new jobs or pipelines in its projects will run."
        end

        it 'displays a warning message on project homepage' do
          visit project_path(project)

          expect_quota_exceeded_alert(message)
        end

        it 'displays a warning message on pipelines page' do
          visit project_pipelines_path(project)

          expect_quota_exceeded_alert(message)
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it 'does not display a warning message on project homepage' do
          visit project_path(project)

          expect_no_quota_exceeded_alert
        end

        it 'does not display a warning message on pipelines page' do
          visit project_pipelines_path(project)

          expect_no_quota_exceeded_alert
        end
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it 'does not display a warning message on project homepage' do
          visit project_path(project)

          expect_no_quota_exceeded_alert
        end

        it 'does not display a warning message on pipelines page' do
          visit project_pipelines_path(project)

          expect_no_quota_exceeded_alert
        end
      end
    end
  end

  context 'when not a project member' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }

    context 'when limit is defined and limit is exceeded' do
      it 'does not display a warning message on project homepage' do
        visit project_path(project)

        expect_no_quota_exceeded_alert
      end

      it 'does not display a warning message on pipelines page' do
        visit project_pipelines_path(project)

        expect_no_quota_exceeded_alert
      end
    end
  end

  def expect_quota_exceeded_alert(message = nil)
    expect(page).to have_selector('.shared-runner-quota-message', count: 1)

    if message
      page.within('.shared-runner-quota-message') do
        expect(page).to have_content(message)
        expect(page).to have_link 'Buy more Pipeline minutes'
      end
    end
  end

  def expect_no_quota_exceeded_alert
    expect(page).not_to have_selector('.shared-runner-quota-message')
  end
end
