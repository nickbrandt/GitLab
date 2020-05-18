# frozen_string_literal: true

require 'spec_helper'

describe Mutations::AlertManagement::UpdateAlertStatus do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, :triggered) }
  let_it_be(:project) { alert.project }
  let(:new_status) { Types::AlertManagement::StatusEnum.values['ACKNOWLEDGED'].value }
  let(:ended_at) { 1.hour.ago }
  let(:args) { { status: new_status, ended_at: ended_at, project_path: project.full_path, iid: alert.iid } }

  specify { expect(described_class).to require_graphql_authorizations(:update_alert_management_alert) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_developer(current_user)
      end

      it 'changes the status' do
        expect { resolve }.to change { alert.reload.acknowledged? }.to(true)
      end

      it 'returns the alert with no errors' do
        expect(resolve).to eq(
          alert: alert,
          errors: []
        )
      end

      context 'error occurs when updating' do
        it 'returns the alert with errors' do
          # invalidate alert
          too_many_hosts = Array.new(AlertManagement::Alert::HOSTS_MAX_LENGTH + 1) { |_| 'host' }
          alert.update_columns(hosts: too_many_hosts)

          expect(resolve).to eq(
            alert: alert,
            errors: ['Hosts hosts array is over 255 chars']
          )
        end

        context 'invalid status given' do
          let(:new_status) { 'invalid_status' }

          it 'returns the alert with errors' do
            expect(resolve).to eq(
              alert: alert,
              errors: [_('Invalid status')]
            )
          end
        end
      end
    end

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
