# frozen_string_literal: true

require 'spec_helper'

describe Projects::TracingsController do
  let_it_be(:user) { create(:user) }

  describe 'GET show' do
    shared_examples 'user with read access' do |visibility_level|
      let(:project) { create(:project, visibility_level) }

      before do
        project.add_maintainer(user)
      end

      it 'renders OK' do
        get :show, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    shared_examples 'user without read access' do |visibility_level|
      let(:project) { create(:project, visibility_level) }

      %w[guest reporter developer].each do |role|
        before do
          project.public_send("add_#{role}", user)
        end

        it 'returns 404' do
          get :show, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'with valid license' do
      before do
        stub_licensed_features(tracing: true)
        sign_in(user)
      end

      context 'with maintainer role' do
        it_behaves_like 'user with read access', :public
        it_behaves_like 'user with read access', :internal
        it_behaves_like 'user with read access', :private
      end

      context 'without maintainer role' do
        it_behaves_like 'user without read access', :public
        it_behaves_like 'user without read access', :internal
        it_behaves_like 'user without read access', :private
      end
    end

    context 'with invalid license' do
      before do
        stub_licensed_features(tracing: false)
        sign_in(user)
      end

      it_behaves_like 'user without read access', :public
      it_behaves_like 'user without read access', :internal
      it_behaves_like 'user without read access', :private
    end
  end
end
