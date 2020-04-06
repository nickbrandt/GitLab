# frozen_string_literal: true

require 'spec_helper'

describe Ci::MinutesNotificationService do
  describe '.call' do
    let_it_be(:user) { create(:user) }
    let(:shared_runners_enabled) { true }
    let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: shared_runners_enabled) }
    let_it_be(:group) { create(:group) }
    let(:namespace) { group }
    let(:prj) { project }

    subject { described_class.call(user, prj, namespace) }

    shared_examples 'showing notification' do
      context 'without limit' do
        it 'returns falsey' do
          expect(subject.show_notification?).to be_falsey
        end
      end

      context 'when limit is defined' do
        context 'when usage has reached a notification level' do
          before do
            group.last_ci_minutes_usage_notification_level = 30
            group.shared_runners_minutes_limit = 10
            allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(2)
          end

          it 'returns truthy' do
            expect(subject.show_notification?).to be_truthy
          end
        end

        context 'when limit not yet exceeded' do
          let(:group) { create(:group, :with_not_used_build_minutes_limit) }

          it 'returns falsey' do
            expect(subject.show_notification?).to be_falsey
          end
        end

        context 'when minutes are not yet set' do
          let(:group) { create(:group, :with_build_minutes_limit) }

          it 'returns falsey' do
            expect(subject.show_notification?).to be_falsey
          end
        end
      end
    end

    shared_examples 'showing alert' do
      context 'without limit' do
        it 'returns falsey' do
          expect(subject.show_notification?).to be_falsey
        end
      end

      context 'when limit is defined' do
        context 'when usage has reached a notification level' do
          before do
            group.last_ci_minutes_usage_notification_level = 30
            group.shared_runners_minutes_limit = 10
            allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(2)
          end

          it 'returns truthy' do
            expect(subject.show_notification?).to be_truthy
          end
        end

        context 'when usage has exceeded the limit' do
          let(:group) { create(:group, :with_used_build_minutes_limit) }

          it 'returns truthy' do
            expect(subject.show_notification?).to be_truthy
          end
        end

        context 'when limit not yet exceeded' do
          let(:group) { create(:group, :with_not_used_build_minutes_limit) }

          it 'returns falsey' do
            expect(subject.show_notification?).to be_falsey
          end
        end

        context 'when minutes are not yet set' do
          let(:group) { create(:group, :with_build_minutes_limit) }

          it 'returns falsey' do
            expect(subject.show_notification?).to be_falsey
          end
        end
      end
    end

    shared_examples 'scoping' do
      describe '#scope' do
        it 'shows full path' do
          expect(subject.scope).to eq level.full_path
        end
      end
    end

    shared_examples 'show notification project constraints' do
      before do
        group.last_ci_minutes_usage_notification_level = 30
        group.shared_runners_minutes_limit = 10
        allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(2)
      end

      context 'when usage has reached a notification level' do
        it 'returns falsey' do
          expect(subject.show_notification?).to be_falsey
        end
      end
    end

    shared_examples 'show alert project constraints' do
      let(:group) { create(:group, :with_used_build_minutes_limit) }

      context 'when usage has reached a notification level' do
        it 'returns falsey' do
          expect(subject.show_alert?).to be_falsey
        end
      end
    end

    shared_examples 'class level items' do
      it 'assigns the namespace' do
        expect(subject.namespace).to eq group
      end
    end

    context 'when at project level' do
      let(:namespace) { nil }
      let(:prj) { project }

      it_behaves_like 'class level items'

      describe '#show_notification?' do
        context 'when project member' do
          it_behaves_like 'showing notification' do
            before do
              group.add_developer(user)
            end
          end
        end

        context 'when not a project member' do
          it_behaves_like 'show notification project constraints'
        end
      end

      describe '#show_alert?' do
        context 'when project member' do
          it_behaves_like 'showing alert' do
            before do
              group.add_developer(user)
            end
          end
        end

        context 'when not a project member' do
          it_behaves_like 'show alert project constraints'
        end
      end

      it_behaves_like 'scoping' do
        let(:level) { project }
      end
    end

    context 'when at namespace level' do
      let(:prj) { nil }

      it_behaves_like 'class level items'

      describe '#show_notification?' do
        context 'with a project that has runners enabled inside namespace' do
          it_behaves_like 'showing notification'
        end

        context 'with no projects that have runners enabled inside namespace' do
          it_behaves_like 'show notification project constraints' do
            let(:shared_runners_enabled) { false }
          end
        end
      end

      describe '#show_alert?' do
        context 'with a project that has runners enabled inside namespace' do
          it_behaves_like 'showing alert'
        end

        context 'with no projects that have runners enabled inside namespace' do
          it_behaves_like 'show alert project constraints' do
            let(:shared_runners_enabled) { false }
          end
        end
      end

      it_behaves_like 'scoping' do
        let(:level) { group }
      end
    end
  end
end
