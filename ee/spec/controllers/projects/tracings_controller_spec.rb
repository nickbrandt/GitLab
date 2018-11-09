# frozen_string_literal: true

require 'spec_helper'

describe Projects::TracingsController do
  set(:user) { create(:user) }

  describe 'GET show' do
    describe 'with valid license' do
      before do
        stub_licensed_features(tracing: true)
      end

      shared_examples 'authorized user' do |visibility_level|
        let(:project) { create(:project, visibility_level) }

        before do
          project.add_reporter(user)
          sign_in(user)
        end

        it 'renders OK' do
          get :show, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template(:show)
        end
      end

      it_behaves_like 'authorized user', :public
      it_behaves_like 'authorized user', :internal
      it_behaves_like 'authorized user', :private

      shared_examples 'unauthorized user' do |visibility_level|
        let(:project) { create(:project, visibility_level) }

        before do
          sign_in(user)
        end

        it 'returns 404' do
          get :show, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'unauthorized user', :public
      it_behaves_like 'unauthorized user', :internal
      it_behaves_like 'unauthorized user', :private
    end

    context 'with invalid license' do
      before do
        stub_licensed_features(tracing: false)
        sign_in(user)
      end

      shared_examples 'invalid license' do |visibility_level|
        let(:project) { create(:project, visibility_level) }

        before do
          stub_licensed_features(tracing: false)
          project.add_reporter(user)
          sign_in(user)
        end

        it 'returns 404' do
          get :show, namespace_id: project.namespace, project_id: project

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it_behaves_like 'invalid license', :public
      it_behaves_like 'invalid license', :internal
      it_behaves_like 'invalid license', :private
    end
  end
end
