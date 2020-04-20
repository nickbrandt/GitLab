# frozen_string_literal: true

require 'spec_helper'

describe Groups::AuditEventsController do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :private) }

  describe 'GET #index' do
    let(:sort) { nil }

    let(:request) do
      get :index, params: { group_id: group.to_param, sort: sort }
    end

    context 'authorized' do
      before do
        group.add_owner(owner)
        sign_in(owner)
      end

      context 'when audit_events feature is available' do
        let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }
        let(:audit_logs_params) { ActionController::Parameters.new(sort: '').permit! }

        before do
          stub_licensed_features(audit_events: true)

          allow(Gitlab::Audit::Levels::Group).to receive(:new).and_return(level)
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

              expect(assigns(:events)).to eq(group.audit_events.order(id: :desc))
            end
          end

          before do
            create_list(:group_audit_event, 5, entity_id: group.id)
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

              expect(assigns(:events)).to eq(group.audit_events.order(id: :asc))
            end
          end

          context 'when sorting by an unsupported sort order' do
            let(:sort) { 'FOO' }

            it_behaves_like 'orders by id descending'
          end
        end

        context 'pagination' do
          it 'paginates audit events, without casting a count query' do
            request

            expect(assigns(:events)).to be_kind_of(Kaminari::PaginatableWithoutCount)
          end
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
