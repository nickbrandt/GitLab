# frozen_string_literal: true

require "spec_helper"

describe EE::RunnersHelper do
  let_it_be(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  shared_examples_for 'minutes notification' do
    let_it_be(:namespace) { create(:namespace, owner: user) }
    let_it_be(:project) { create(:project, namespace: namespace) }
    let(:show_warning) { true }
    let(:context_level) { project }
    let(:threshold) { double('Ci::Minutes::Notification', show?: show_warning) }

    before do
      allow(::Ci::Minutes::Notification).to receive(:new).and_return(threshold)
    end

    context 'with a project and namespace' do
      context 'when experiment is disabled' do
        let(:experiment_status) { false }

        it { is_expected.to be_falsey }
      end

      context 'when experiment is enabled' do
        it { is_expected.to be_truthy }

        context 'without a persisted project passed' do
          let(:project) { build(:project) }
          let(:context_level) { namespace }

          it { is_expected.to be_truthy }
        end

        context 'without a persisted namespace passed' do
          let(:namespace) { build(:namespace) }

          it { is_expected.to be_truthy }
        end

        context 'with neither a project nor a namespace' do
          let(:project) { build(:project) }
          let(:namespace) { build(:namespace) }

          it { is_expected.to be_falsey }

          context 'when show_ci_minutes_notification_dot? has been called before' do
            it 'does not do all the notification and query work again' do
              expect(threshold).not_to receive(:show?)
              expect(project).to receive(:persisted?).once

              helper.show_ci_minutes_notification_dot?(project, namespace)

              expect(subject).to be_falsey
            end
          end
        end

        context 'when show notification is falsey' do
          let(:show_warning) { false }

          it { is_expected.to be_falsey }
        end

        context 'when show_ci_minutes_notification_dot? has been called before' do
          it 'does not do all the notification and query work again' do
            expect(threshold).to receive(:show?).once
            expect(project).to receive(:persisted?).once

            helper.show_ci_minutes_notification_dot?(project, namespace)

            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  context 'with notifications' do
    let(:experiment_status) { true }

    describe '.show_buy_ci_minutes?' do
      subject { helper.show_buy_ci_minutes?(project, namespace) }

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
      subject { helper.show_ci_minutes_notification_dot?(project, namespace) }

      it_behaves_like 'minutes notification' do
        before do
          allow(helper).to receive(:experiment_enabled?).with(:ci_notification_dot).and_return(experiment_status)
        end
      end
    end
  end
end
