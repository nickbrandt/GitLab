# frozen_string_literal: true

require 'spec_helper'

describe Groups::AuditEventsController do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :private) }

  describe 'GET #index' do
    let(:request) do
      get :index, params: { group_id: group.to_param }
    end

    context 'authorized' do
      before do
        group.add_owner(owner)
        sign_in(owner)
      end

      context 'when audit_events feature is available' do
        let(:audit_logs_params) { ActionController::Parameters.new(entity_type: ::Group.name, entity_id: group.id).permit! }

        before do
          stub_licensed_features(audit_events: true)
        end

        it 'renders index with 200 status code' do
          expect(AuditLogFinder).to receive(:new).with(audit_logs_params).and_call_original

          request

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:index)
        end

        context 'ordering' do
          before do
            create_list(:group_audit_event, 5, entity_id: group.id)
          end

          it 'orders by id descending' do
            request

            expect(assigns(:events)).to eq(group.audit_events.order(id: :desc))
          end
        end
      end

      context 'when audit_events feature is not available' do
        before do
          stub_licensed_features(audit_events: false)
        end

        it 'renders 404' do
          request

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'unauthorized' do
      before do
        stub_licensed_features(audit_events: true)
        sign_in(user)
      end

      it 'renders 404' do
        request

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
