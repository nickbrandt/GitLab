# frozen_string_literal: true

require 'spec_helper'

describe Mutations::AlertManagement::UpdateAlertStatus do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, status: 'triggered') }
  let_it_be(:project) { alert.project }
  let(:new_status) { 'acknowledged' }
  let(:args) { { status: new_status, project_path: project.full_path, iid: alert.iid } }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_developer(current_user)
      end

      it 'changes the status' do
        expect { resolve }.to change { alert.reload.status }.from(alert.status).to(new_status)
      end

      it 'returns the alert with no errors' do
        expect(resolve).to eq(
          alert: alert,
          errors: []
        )
      end

      context 'error occurs when updating' do
        before do
          # Stubbing and error on alert
          allow_next_instance_of(Resolvers::AlertManagementAlertResolver) do |resolver|
            allow(resolver).to receive(:resolve).and_return(alert)
          end

          expect(alert).to receive(:save).and_return(false)

          errors = ActiveModel::Errors.new(alert)
          errors.add(:status, :invalid)

          expect(alert).to receive(:errors).and_return(errors)
        end

        it 'returns the alert with no errors' do
          expect(resolve).to eq(
            alert: alert,
            errors: ['Status is invalid']
          )
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
