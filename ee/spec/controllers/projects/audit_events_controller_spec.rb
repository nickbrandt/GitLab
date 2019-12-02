# frozen_string_literal: true

require 'spec_helper'

describe Projects::AuditEventsController do
  let(:user) { create(:user) }
  let(:maintainer) { create(:user) }
  let(:project) { create(:project, :private) }

  describe 'GET #index' do
    let(:request) do
      get :index, params: { project_id: project.to_param, namespace_id: project.namespace.to_param }
    end

    context 'authorized' do
      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when audit_events feature is available' do
        let(:audit_logs_params) { ActionController::Parameters.new(entity_type: ::Project.name, entity_id: project.id).permit! }

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
            create_list(:project_audit_event, 5, entity_id: project.id)
          end

          it 'orders by id descending' do
            request

            expect(assigns(:events)).to eq(project.audit_events.order(id: :desc))
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
