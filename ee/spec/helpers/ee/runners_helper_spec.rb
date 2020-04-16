# frozen_string_literal: true

require "spec_helper"

describe EE::RunnersHelper do
  let_it_be(:user, reload: true) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.ci_usage_warning_message' do
    let(:project) { create(:project, namespace: namespace) }
    let(:minutes_used) { 0 }

    let(:namespace) do
      create(:group, shared_runners_minutes_limit: 100)
    end

    let!(:statistics) do
      create(:namespace_statistics, namespace: namespace, shared_runners_seconds: minutes_used * 60)
    end

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).with(user, :admin_project, project) { false }

      stub_const("EE::Namespace::CI_USAGE_ALERT_LEVELS", [50])
    end

    subject { helper.ci_usage_warning_message(namespace, project) }

    context 'when CI minutes quota is above the warning limits' do
      let(:minutes_used) { 40 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the last_ci_minutes_usage_notification_level field is set' do
      before do
        namespace.update_attribute(:last_ci_minutes_usage_notification_level, 50)
      end

      context 'when there are minutes used but remaining minutes percent is still below the notification threshold' do
        let(:minutes_used) { 51 }

        it 'returns the partial usage notification message' do
          expect(subject).to match("#{namespace.name} has less than 50% of CI minutes available.")
        end
      end

      context 'when limit is increased so there are now more remaining minutes percentage than the notification threshold' do
        before do
          namespace.update(shared_runners_minutes_limit: 200)
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when there are no more remaining minutes' do
        let(:minutes_used) { 100 }

        it 'returns the exceeded usage message' do
          expect(subject).to match("#{namespace.name} has exceeded its pipeline minutes quota.")
        end
      end
    end

    context 'when current user is an owner' do
      before do
        allow(helper).to receive(:can?).with(user, :admin_project, project) { true }
      end

      context 'when base message is not present' do
        before do
          allow(helper).to receive(:ci_usage_base_message).with(namespace).and_return(nil)
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when usage has reached first level of notification' do
        let(:minutes_used) { 50 }

        before do
          namespace.update_attribute(:last_ci_minutes_usage_notification_level, 50)
        end

        it 'shows the partial usage message' do
          expect(subject).to match("#{namespace.name} has less than 50% of CI minutes available.")
          expect(subject).to match('to purchase more minutes')
        end
      end

      context 'when usage is above the quota' do
        let(:minutes_used) { 120 }

        it 'shows the total usage message' do
          expect(subject).to match("#{namespace.name} has exceeded its pipeline minutes quota.")
          expect(subject).to match('to purchase more minutes')
        end
      end
    end

    context 'when current user is not an owner' do
      context 'when base message is not present' do
        before do
          allow(helper).to receive(:ci_usage_base_message).with(namespace).and_return(nil)
        end

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'when usage has reached first level of notification' do
        let(:minutes_used) { 50 }

        before do
          namespace.update_attribute(:last_ci_minutes_usage_notification_level, 50)
        end

        it 'shows the partial usage message without the purchase link' do
          expect(subject).to match("#{namespace.name} has less than 50% of CI minutes available.")
          expect(subject).not_to match('to purchase more minutes')
        end
      end

      context 'when usage is above the quota' do
        let(:minutes_used) { 120 }

        it 'shows the total usage message without the purchase link' do
          expect(subject).to match("#{namespace.name} has exceeded its pipeline minutes quota.")
          expect(subject).not_to match('to purchase more minutes')
        end
      end
    end
  end

  shared_examples_for 'minutes notification' do
    let_it_be(:namespace) { create(:namespace, owner: user) }
    let_it_be(:project) { create(:project, namespace: namespace) }
    let(:injected_project) { project }
    let(:injected_namespace) { namespace }
    let(:show_warning) { true }
    let(:context_level) { project }
    let(:context) { double('Ci::Minutes::Context', level: context_level, namespace: namespace) }
    let(:threshold) { double('Ci::Minutes::Threshold', warning_reached?: show_warning) }
    let!(:user_pipeline) { create(:ci_pipeline, user: user, project: project) }

    before do
      allow(::Ci::Minutes::Context).to receive(:new).and_return(context)
      allow(::Ci::Minutes::Threshold).to receive(:new).and_return(threshold)
    end

    context 'with a project and namespace' do
      context 'when experiment is disabled' do
        let(:experiment_status) { false }

        it { is_expected.to be_falsey }
      end

      context 'when experiment is enabled with user pipelines' do
        it { is_expected.to be_truthy }

        context 'without a persisted project passed' do
          let(:injected_project) { build(:project) }
          let(:context_level) { namespace }

          it { is_expected.to be_truthy }
        end

        context 'without a persisted namespace passed' do
          let(:injected_namespace) { build(:namespace) }

          it { is_expected.to be_truthy }
        end

        context 'with neither a project nor a namespace' do
          let(:injected_project) { build(:project) }
          let(:injected_namespace) { build(:namespace) }

          it { is_expected.to be_falsey }

          context 'when show_ci_minutes_notification_dot? has been called before' do
            it 'does not do all the notification and query work again' do
              expect(threshold).not_to receive(:warning_reached?)
              expect(injected_project).to receive(:persisted?).once

              helper.show_ci_minutes_notification_dot?(injected_project, injected_namespace)

              expect(subject).to be_falsey
            end
          end
        end

        context 'when show notification is falsey' do
          let(:show_warning) { false }

          it { is_expected.to be_falsey }
        end

        context 'without user pipelines' do
          before do
            user.pipelines.clear # this forces us to reload user for let_it_be
          end

          it { is_expected.to be_falsey }
        end

        context 'when show_ci_minutes_notification_dot? has been called before' do
          it 'does not do all the notification and query work again' do
            expect(threshold).to receive(:warning_reached?).once
            expect(project).to receive(:persisted?).once

            helper.show_ci_minutes_notification_dot?(project, namespace)

            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  context 'with pipelines' do
    let(:experiment_status) { true }

    describe '.show_buy_ci_minutes?' do
      subject { helper.show_buy_ci_minutes?(injected_project, injected_namespace) }

      context 'when experiment is "ci_notification_dot"' do
        it_behaves_like 'minutes notification' do
          before do
            allow(helper).to receive(:experiment_enabled?).with(:ci_notification_dot).and_return(experiment_status)
            allow(helper).to receive(:experiment_enabled?).with(:buy_ci_minutes_version_a).and_return(false)
          end
        end
      end

      context 'when experiment is "ci_minutes_version_a"' do
        it_behaves_like 'minutes notification' do
          before do
            allow(helper).to receive(:experiment_enabled?).with(:ci_notification_dot).and_return(false)
            allow(helper).to receive(:experiment_enabled?).with(:buy_ci_minutes_version_a).and_return(experiment_status)
          end
        end
      end
    end

    describe '.show_ci_minutes_notification_dot?' do
      subject { helper.show_ci_minutes_notification_dot?(injected_project, injected_namespace) }

      it_behaves_like 'minutes notification' do
        before do
          allow(helper).to receive(:experiment_enabled?).with(:ci_notification_dot).and_return(experiment_status)
        end
      end
    end
  end
end
