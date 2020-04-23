# frozen_string_literal: true

require 'spec_helper'

describe Ci::Minutes::Threshold do
  let_it_be(:user) { create(:user) }
  let(:shared_runners_enabled) { true }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: shared_runners_enabled) }
  let_it_be(:group) { create(:group) }
  let(:injected_group) { group }
  let(:injected_project) { project }

  shared_examples 'queries for warning being reached' do
    context 'without limit' do
      it { is_expected.to be_falsey }
    end

    context 'when limit is defined' do
      context 'when usage has reached a notification level' do
        before do
          group.shared_runners_minutes_limit = 10
          allow(group).to receive(:shared_runners_remaining_minutes).and_return(2)
        end

        context 'when over the limit' do
          before do
            group.last_ci_minutes_usage_notification_level = 30
          end

          it { is_expected.to be_truthy }
        end

        context 'when right at the limit for notification' do
          before do
            group.last_ci_minutes_usage_notification_level = 20
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end
  end

  shared_examples 'queries for alert being reached' do
    context 'without limit' do
      it { is_expected.to be_falsey }
    end

    context 'when limit is defined' do
      context 'when usage has exceeded the limit' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }

        it { is_expected.to be_truthy }
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end
  end

  shared_examples 'cannot see if warning reached' do
    before do
      group.last_ci_minutes_usage_notification_level = 30
      group.shared_runners_minutes_limit = 10
      allow(group).to receive(:shared_runners_remaining_minutes).and_return(2)
    end

    context 'when usage has not reached a warning level' do
      it { is_expected.to be_falsey }
    end
  end

  shared_examples 'cannot see if alert reached' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }

    context 'when usage has reached an alert level' do
      it { is_expected.to be_falsey }
    end
  end

  context 'when at project level' do
    let(:context) { ::Ci::Minutes::Context.new(user, injected_project, nil) }

    describe '#warning_reached?' do
      subject do
        threshold = described_class.new(context)
        threshold.warning_reached?
      end

      context 'when eligible to see warnings' do
        it_behaves_like 'queries for warning being reached' do
          before do
            group.add_developer(user)
          end
        end
      end

      context 'when not eligible to see warnings' do
        it_behaves_like 'cannot see if warning reached'
      end
    end

    describe '#alert_reached?' do
      subject do
        threshold = described_class.new(context)
        threshold.alert_reached?
      end

      context 'when eligible to see alerts' do
        it_behaves_like 'queries for alert being reached' do
          before do
            group.add_developer(user)
          end
        end
      end

      context 'when not eligible to see alerts' do
        it_behaves_like 'cannot see if alert reached'
      end
    end
  end

  context 'when at namespace level' do
    let(:context) { ::Ci::Minutes::Context.new(user, nil, injected_group) }

    describe '#warning_reached?' do
      subject do
        threshold = described_class.new(context)
        threshold.warning_reached?
      end

      context 'when eligible to see warnings' do
        let!(:user_pipeline) { create(:ci_pipeline, user: user, project: project) }

        context 'with a project that has runners enabled inside namespace' do
          it_behaves_like 'queries for warning being reached'
        end

        context 'with no projects that have runners enabled inside namespace' do
          it_behaves_like 'cannot see if warning reached' do
            let(:shared_runners_enabled) { false }
          end
        end
      end

      context 'when not eligible to see warnings' do
        it_behaves_like 'cannot see if warning reached'
      end
    end

    describe '#alert_reached?' do
      subject do
        threshold = described_class.new(context)
        threshold.alert_reached?
      end

      context 'when eligible to see warnings' do
        let!(:user_pipeline) { create(:ci_pipeline, user: user, project: project) }

        context 'with a project that has runners enabled inside namespace' do
          it_behaves_like 'queries for alert being reached'
        end

        context 'with no projects that have runners enabled inside namespace' do
          it_behaves_like 'cannot see if alert reached' do
            let(:shared_runners_enabled) { false }
          end
        end
      end

      context 'when not eligible to see warnings' do
        it_behaves_like 'cannot see if warning reached'
      end
    end

    context 'when we have already checked to see if we can show the limit' do
      subject { described_class.new(context) }

      it 'does not do all the verification work again' do
        expect(context).to receive(:shared_runners_minutes_limit_enabled?).once

        subject.warning_reached?
        subject.alert_reached?
      end
    end
  end
end
