# frozen_string_literal: true

require 'spec_helper'

describe Users::DestroyService do
  let(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    it 'returns result' do
      allow(user).to receive(:destroy).and_return(user)

      expect(operation).to eq(user)
    end

    context 'when project is a mirror' do
      let(:project) { create(:project, :mirror, mirror_user_id: user.id) }

      it 'assigns mirror_user to a project owner' do
        new_mirror_user = project.team.owners.first

        expect_any_instance_of(EE::NotificationService)
          .to receive(:project_mirror_user_changed)
          .with(new_mirror_user, user.name, project)

        expect { operation }.to change { project.reload.mirror_user }
          .from(user).to(new_mirror_user)
      end
    end

    describe 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'soft delete' do
          let(:hard_delete) { false }

          context 'when user destroy operation succeeds' do
            it 'logs audit events for ghost user migration and destroy operation' do
              service.execute(user, hard_delete: hard_delete)

              expect(AuditEvent.last(3)).to contain_exactly(
                have_attributes(details: hash_including(change: 'email address')),
                have_attributes(details: hash_including(change: 'username')),
                have_attributes(details: hash_including(remove: 'user'))
              )
            end
          end

          context 'when user destroy operation fails' do
            before do
              allow(user).to receive(:destroy).and_return(false)
            end

            it 'logs audit events for ghost user migration operation' do
              service.execute(user, hard_delete: hard_delete)

              expect(AuditEvent.last(2)).to contain_exactly(
                have_attributes(details: hash_including(change: 'email address')),
                have_attributes(details: hash_including(change: 'username'))
              )
            end
          end
        end

        context 'hard delete' do
          let(:hard_delete) { true }

          context 'when user destroy operation succeeds' do
            it 'logs audit events for destroy operation' do
              service.execute(user, hard_delete: hard_delete)

              expect(AuditEvent.last)
                .to have_attributes(details: hash_including(remove: 'user'))
            end
          end

          context 'when user destroy operation fails' do
            before do
              allow(user).to receive(:destroy).and_return(false)
            end

            it 'does not log any audit event' do
              expect { service.execute(user, hard_delete: hard_delete) }
                .not_to change { AuditEvent.count }
            end
          end
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(
            admin_audit_log: false,
            audit_events: false,
            extended_audit_events: false
          )
        end

        it 'does not log any audit event' do
          expect { service.execute(user) }
            .not_to change { AuditEvent.count }
        end
      end
    end
  end
end
