# frozen_string_literal: true

require 'spec_helper'

describe CiMinutesUsageNotifyService do
  shared_examples 'namespace with available CI minutes' do
    context 'when usage is below the quote' do
      it 'does not send the email' do
        expect(CiMinutesUsageMailer).not_to receive(:notify)

        subject
      end
    end
  end

  shared_examples 'namespace with all CI minutes used' do
    context 'when usage is over the quote' do
      it 'sends the email to the owner' do
        expect(CiMinutesUsageMailer).to receive(:notify).once.with(namespace.name, user.email).and_return(spy)

        subject
      end
    end
  end

  describe '#execute' do
    let(:extra_ci_minutes) { 0 }
    let(:namespace) do
      create(:namespace, shared_runners_minutes_limit: 2000, extra_shared_runners_minutes_limit: extra_ci_minutes)
    end

    let(:project) { create(:project, namespace: namespace) }
    let(:user) { create(:user) }
    let(:user_2) { create(:user) }

    let(:ci_minutes_used) { 0 }
    let!(:namespace_statistics) do
      create(:namespace_statistics, namespace: namespace, shared_runners_seconds: ci_minutes_used * 60)
    end

    subject { described_class.new(project).execute }

    context 'with a personal namespace' do
      before do
        namespace.update(owner_id: user.id)
      end

      it_behaves_like 'namespace with available CI minutes' do
        let(:ci_minutes_used) { 1900 }
      end

      it_behaves_like 'namespace with all CI minutes used' do
        let(:ci_minutes_used) { 2500 }
      end
    end

    context 'with a Group' do
      let!(:namespace) do
        create(:group, shared_runners_minutes_limit: 2000, extra_shared_runners_minutes_limit: extra_ci_minutes)
      end

      context 'with a single owner' do
        before do
          namespace.add_owner(user)
        end

        it_behaves_like 'namespace with available CI minutes' do
          let(:ci_minutes_used) { 1900 }
        end

        it_behaves_like 'namespace with all CI minutes used' do
          let(:ci_minutes_used) { 2500 }
        end

        context 'with extra CI minutes' do
          let(:extra_ci_minutes) { 1000 }

          it_behaves_like 'namespace with available CI minutes' do
            let(:ci_minutes_used) { 2500 }
          end

          it_behaves_like 'namespace with all CI minutes used' do
            let(:ci_minutes_used) { 3100 }
          end
        end
      end

      context 'with multiple owners' do
        before do
          namespace.add_owner(user)
          namespace.add_owner(user_2)
        end

        it_behaves_like 'namespace with available CI minutes' do
          let(:ci_minutes_used) { 1900 }
        end

        context 'when usage is over the quote' do
          let(:ci_minutes_used) { 2001 }

          it 'sends the email to all the owners' do
            expect(CiMinutesUsageMailer).to receive(:notify).with(namespace.name, user.email).and_return(spy)
            expect(CiMinutesUsageMailer).to receive(:notify).with(namespace.name, user_2.email).and_return(spy)

            subject
          end

          context 'when last_ci_minutes_notification_at has a value' do
            before do
              namespace.update_attribute(:last_ci_minutes_notification_at, Time.now)
            end

            it 'does not notify owners' do
              expect(CiMinutesUsageMailer).not_to receive(:notify)

              subject
            end
          end
        end
      end
    end
  end
end
