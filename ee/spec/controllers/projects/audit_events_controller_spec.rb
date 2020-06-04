# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AuditEventsController do
  let(:user) { create(:user) }
  let(:maintainer) { create(:user) }
  let(:project) { create(:project, :private) }

  describe 'GET #index' do
    let(:sort) { nil }

    let(:request) do
      get :index, params: { project_id: project.to_param, namespace_id: project.namespace.to_param, sort: sort }
    end

    context 'authorized' do
      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when audit_events feature is available' do
        let(:level) { Gitlab::Audit::Levels::Project.new(project: project) }
        let(:audit_logs_params) { ActionController::Parameters.new(sort: '').permit! }

        before do
          stub_licensed_features(audit_events: true)

          allow(Gitlab::Audit::Levels::Project).to receive(:new).and_return(level)
          allow(AuditLogFinder).to receive(:new).and_call_original
        end

        it 'renders index with 200 status code' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
        end

        it 'invokes AuditLogFinder with correct arguments' do
          request

          expect(AuditLogFinder).to have_received(:new).with(
            level: level, params: audit_logs_params
          )
        end

        context 'ordering' do
          shared_examples 'orders by id descending' do
            it 'orders by id descending' do
              request

              expect(assigns(:events)).to eq(project.audit_events.order(id: :desc))
            end
          end

          before do
            create_list(:project_audit_event, 5, entity_id: project.id)
          end

          context 'when no sort order is specified' do
            it_behaves_like 'orders by id descending'
          end

          context 'when sorting by latest events first' do
            let(:sort) { 'created_desc' }

            it_behaves_like 'orders by id descending'
          end

          context 'when sorting by oldest events first' do
            let(:sort) { 'created_asc' }

            it 'orders by id ascending' do
              request

              expect(assigns(:events)).to eq(project.audit_events.order(id: :asc))
            end
          end

          context 'when sorting by an unsupported sort order' do
            let(:sort) { 'FOO' }

            it_behaves_like 'orders by id descending'
          end
        end
      end

      context 'when audit_events feature is not available' do
        before do
          stub_licensed_features(audit_events: false)
        end

        it 'renders 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
