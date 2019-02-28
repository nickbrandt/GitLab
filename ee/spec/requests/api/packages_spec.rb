# frozen_string_literal: true

require 'spec_helper'

describe API::Packages do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:package) { create(:npm_package, project: project) }
  let(:package_url) { "/projects/#{project.id}/packages/#{package.id}" }
  let(:another_package) { create(:npm_package) }
  let(:no_package_url) { "/projects/#{project.id}/packages/0" }
  let(:wrong_package_url) { "/projects/#{project.id}/packages/#{another_package.id}" }

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
          get api(no_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 200 and valid response schema' do
          project.add_maintainer(user)

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
          project.add_maintainer(user)
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

  describe 'GET /projects/:id/packages/:package_id' do
    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it 'returns 200 and the package information' do
          get api(package_url, user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/packages/package', dir: 'ee')
        end

        it 'returns 404 when the package does not exist' do
          get api(no_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for the package from a different project' do
          get api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          get api(package_url)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for a user without access to the project' do
          get api(package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 200 and the package information' do
          project.add_developer(user)

          get api(package_url, user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/packages/package', dir: 'ee')
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        get api(package_url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id' do
    context 'packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'project is public' do
        it 'returns 403 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns 403 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 when the package does not exist' do
          project.add_maintainer(user)

          delete api(no_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 404 for the package from a different project' do
          project.add_maintainer(user)

          delete api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(404)
        end

        it 'returns 403 for a user without enough permissions' do
          project.add_developer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns 204' do
          project.add_maintainer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(204)
        end
      end
    end

    context 'packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it 'returns 403' do
        delete api(package_url, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
