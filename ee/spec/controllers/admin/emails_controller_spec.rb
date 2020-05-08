# frozen_string_literal: true

require 'spec_helper'

describe Admin::EmailsController do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  describe 'GET #show' do
    subject { get :show }

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'when `send_emails_from_admin_area` feature is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: true)
        end

        it 'responds with 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when `send_emails_from_admin_area` feature is disabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    subject do
      post :create, params: {
        recipients: 'all',
        subject: 'subject',
        body: 'body'
      }
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'when `send_emails_from_admin_area` feature is enabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: true)
        end

        it 'trigger the background job to send emails' do
          expect(AdminEmailsWorker).to receive(:perform_async).with('all', 'subject', 'body')

          subject
        end

        it 'redirects to `admin_email_path`' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(admin_email_path)
          expect(flash[:notice]).to eq('Email sent')
        end
      end

      context 'when `send_emails_from_admin_area` feature is disabled' do
        before do
          stub_licensed_features(send_emails_from_admin_area: false)
        end

        it 'does not trigger the background job to send emails' do
          expect(AdminEmailsWorker).not_to receive(:perform_async)

          subject
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
