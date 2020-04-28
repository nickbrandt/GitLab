# frozen_string_literal: true

require 'spec_helper'

describe Mutations::AlertManagement::ChangeAlertStatus do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert) }
  let(:project) { alert.project }
  let(:new_status) { 'acknowledged' }
  let(:args) { { status: new_status, project_path: project.full_path, iid: alert.iid } }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(args) }

    context 'user has access to project' do
      before do
        project.add_developer(current_user)
      end

      it 'does not change the status' do
        expect { resolve }.to change { alert.reload.status }.from(alert.status).to(new_status)
      end
    end

    context 'user has no access' do
      it 'does not change the status' do
        expect { resolve }.not_to change { alert.reload.status }
      end

      it 'sets the error' do
        expect(resolve.dig(:errors)).not_to be_empty
      end
    end
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
