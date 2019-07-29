# frozen_string_literal: true

require 'spec_helper'

describe API::Repositories do
  let(:project) { create(:project, :repository) }

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    shared_examples 'logs the audit event' do
      let(:route) { "/projects/#{project.id}/repository/archive" }

      it 'logs the audit event' do
        expect do
          get api(route, current_user)
        end.to change { SecurityEvent.count }.by(1)
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'logs the audit event' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated', 'as a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'logs the audit event' do
        let(:user) { create(:user) }
        let(:current_user) { user }
      end
    end
  end
end
