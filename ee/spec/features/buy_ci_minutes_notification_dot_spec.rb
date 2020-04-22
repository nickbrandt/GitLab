# frozen_string_literal: true

require 'spec_helper'

describe 'User notification dot', :aggregate_failures do
  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, namespace: group, creator: user, shared_runners_enabled: true) }
  let(:group) { create(:group) }
  let!(:user_pipelines) { create(:ci_pipeline, user: user, project: project) }

  before do
    stub_experiment_for_user(ci_notification_dot: true)
    group.add_developer(user)

    sign_in(user)
  end

  context 'when ci minutes are below threshold' do
    before do
      allow(Gitlab).to receive(:com?) { true }

      group.update(last_ci_minutes_usage_notification_level: 30, shared_runners_minutes_limit: 10)
      allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(2)
    end

    it 'shows notification dot' do
      expect_next_instance_of(ProjectsController) do |ctrl|
        expect(ctrl).to receive(:track_event)
                          .with('show_buy_ci_minutes_notification', label: 'free', property: 'user_dropdown')
      end

      visit project_path(project)

      expect(page).to have_css('span', class: 'header-user-notification-dot')
    end
  end

  context 'when ci minutes are not below threshold' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }

    it 'shows notification dot' do
      expect_next_instance_of(ProjectsController) do |ctrl|
        expect(ctrl).not_to receive(:track_event)
      end

      visit project_path(project)

      expect(page).not_to have_css('span', class: 'header-user-notification-dot')
    end
  end
end
