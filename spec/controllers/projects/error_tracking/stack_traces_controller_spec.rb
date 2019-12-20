# frozen_string_literal: true

require 'spec_helper'

describe Projects::ErrorTracking::StackTracesController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #index' do
    let_it_be(:issue_id) { 1234 }

    let(:issue_stack_trace_service) { spy(:issue_stack_trace_service) }

    subject(:get_stack_trace) do
      get :index, params: { namespace_id: project.namespace, project_id: project, issue_id: issue_id, format: :json }
    end

    before do
      expect(ErrorTracking::IssueLatestEventService)
        .to receive(:new).with(project, user, issue_id: issue_id.to_s)
        .and_return(issue_stack_trace_service)
    end

    context 'awaiting data' do
      before do
        expect(issue_stack_trace_service).to receive(:execute)
          .and_return(status: :error, http_status: :no_content)
      end

      it 'returns no data' do
        get_stack_trace

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'service result is successful' do
      before do
        expect(issue_stack_trace_service).to receive(:execute)
          .and_return(status: :success, latest_event: error_event)

        get_stack_trace
      end

      let(:error_event) { build(:error_tracking_error_event) }

      it 'returns an error' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('error_tracking/issue_stack_trace')
      end

      it 'highlights stack trace source code' do
        expect(json_response['error']).to eq(
          Gitlab::ErrorTracking::StackTraceHighlightDecorator.decorate(error_event).as_json
        )
      end
    end

    context 'service result is erroneous' do
      let(:error_message) { 'error message' }

      context 'without http_status' do
        before do
          expect(issue_stack_trace_service).to receive(:execute)
            .and_return(status: :error, message: error_message)
        end

        it 'returns 400 with message' do
          get_stack_trace

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(error_message)
        end
      end

      context 'with explicit http_status' do
        let(:http_status) { :no_content }

        before do
          expect(issue_stack_trace_service).to receive(:execute).and_return(
            status: :error,
            message: error_message,
            http_status: http_status
          )
        end

        it 'returns http_status with message' do
          get_stack_trace

          expect(response).to have_gitlab_http_status(http_status)
          expect(json_response['message']).to eq(error_message)
        end
      end
    end
  end
end
