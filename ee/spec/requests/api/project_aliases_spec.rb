# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectAliases, api: true do
  set(:user)  { create(:user) }
  set(:admin) { create(:admin) }

  context 'without premium license' do
    describe 'GET /project_aliases' do
      before do
        get api('/project_aliases', admin)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    describe 'GET /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      before do
        get api("/project_aliases/#{project_alias.name}", admin)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    describe 'POST /project_aliases' do
      let(:project) { create(:project) }

      before do
        post api("/project_aliases", admin), params: { project_id: project.id, name: 'some-project' }
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    describe 'DELETE /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      before do
        delete api("/project_aliases/#{project_alias.name}", admin)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  context 'with premium license' do
    before do
      create(:license, plan: License::PREMIUM_PLAN)
    end

    describe 'GET /project_aliases' do
      context 'anonymous user' do
        before do
          get api('/project_aliases')
        end

        it 'returns 401' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'regular user' do
        before do
          get api('/project_aliases', user)
        end

        it 'returns 403' do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'admin' do
        let!(:project_alias_1) { create(:project_alias) }
        let!(:project_alias_2) { create(:project_alias) }

        before do
          get api('/project_aliases', admin)
        end

        it 'returns the project aliases list' do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/project_aliases', dir: 'ee')
        end
      end
    end

    describe 'GET /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      context 'anonymous user' do
        before do
          get api("/project_aliases/#{project_alias.name}")
        end

        it 'returns 401' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'regular user' do
        before do
          get api("/project_aliases/#{project_alias.name}", user)
        end

        it 'returns 403' do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'admin' do
        context 'existing project alias' do
          before do
            get api("/project_aliases/#{project_alias.name}", admin)
          end

          it 'returns the project alias' do
            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/project_alias', dir: 'ee')
          end
        end

        context 'non-existent project alias' do
          before do
            get api("/project_aliases/some-project", admin)
          end

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end

    describe 'POST /project_aliases' do
      let(:project) { create(:project) }

      context 'anonymous user' do
        before do
          post api("/project_aliases")
        end

        it 'returns 401' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'regular user' do
        before do
          post api("/project_aliases", user)
        end

        it 'returns 403' do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'admin' do
        context 'existing project alias' do
          let(:project_alias) { create(:project_alias) }

          before do
            post api("/project_aliases", admin), params: { project_id: project.id, name: project_alias.name }
          end

          it 'returns 400' do
            expect(response).to have_gitlab_http_status(400)
          end
        end

        context 'non-existent project alias' do
          before do
            post api("/project_aliases", admin), params: { project_id: project.id, name: 'some-project' }
          end

          it 'returns 200' do
            expect(response).to have_gitlab_http_status(201)
            expect(response).to match_response_schema('public_api/v4/project_alias', dir: 'ee')
          end
        end
      end
    end

    describe 'DELETE /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      context 'anonymous user' do
        before do
          delete api("/project_aliases/#{project_alias.name}")
        end

        it 'returns 401' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'regular user' do
        before do
          delete api("/project_aliases/#{project_alias.name}", user)
        end

        it 'returns 403' do
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'admin' do
        context 'existing project alias' do
          before do
            delete api("/project_aliases/#{project_alias.name}", admin)
          end

          it 'returns 204' do
            expect(response).to have_gitlab_http_status(204)
          end
        end

        context 'non-existent project alias' do
          before do
            delete api("/project_aliases/some-project", admin)
          end

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end
  end
end
