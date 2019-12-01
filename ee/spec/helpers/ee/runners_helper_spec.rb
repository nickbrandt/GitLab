# frozen_string_literal: true

require "spec_helper"

describe EE::RunnersHelper do
  describe '.ci_usage_warning_message' do
    let(:project) { create(:project, namespace: namespace) }
    let(:minutes_used) { 0 }
    let(:user) { create(:user) }

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
end
