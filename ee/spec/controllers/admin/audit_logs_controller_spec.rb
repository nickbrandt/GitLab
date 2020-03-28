# frozen_string_literal: true

require 'spec_helper'

describe Admin::AuditLogsController do
  let(:admin) { create(:admin) }

  describe 'GET #index' do
    before do
      sign_in(admin)
    end

    context 'licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      context 'pagination' do
        it 'paginates audit events, without casting a count query' do
          create(:user_audit_event, created_at: 5.days.ago)

          get :index, params: { 'entity_type': 'User' }

          expect(assigns(:events)).to be_kind_of(Kaminari::PaginatableWithoutCount)
        end
      end
    end
  end
end
