# frozen_string_literal: true

require 'spec_helper'

describe API::Packages do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:package) { create(:npm_package, project: project) }

  before do
    project.add_developer(user)
  end

  describe 'GET /projects/:id/packages' do
    let(:url) { "/projects/#{project.id}/packages" }

    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it 'returns 200' do
          get api(url)

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          get api(url)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for a user without access to the project' do
          project.team.truncate

          get api(url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 200 and valid response schema' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/packages/packages', dir: 'ee')
        end
      end

      context 'with pagination params' do
        let(:per_page) { 2 }
        let!(:package1) { create(:npm_package, project: project) }
        let!(:package2) { create(:npm_package, project: project) }
        let!(:package3) { create(:maven_package, project: project) }

        before do
          stub_licensed_features(packages: true)
        end

        context 'when viewing the first page' do
          it 'returns first 2 packages' do
            get api(url, user), params: { page: 1, per_page: per_page }

            expect_paginated_array_response([package1.id, package2.id])
          end
        end

        context 'viewing the second page' do
          it 'returns the last package' do
            get api(url, user), params: { page: 2, per_page: per_page }

            expect_paginated_array_response([package3.id])
          end
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        get api(url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
