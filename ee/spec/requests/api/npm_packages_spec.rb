# frozen_string_literal: true
require 'spec_helper'

describe API::NpmPackages do
  let(:group)   { create(:group) }
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:token)   { create(:oauth_access_token, scopes: 'api', resource_owner: user) }

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)
  end

  shared_examples 'a package that requires auth' do
    it 'returns the package info with oauth token' do
      get_package_with_token(package)

      expect_a_valid_package_response
    end

    it 'denies request without oauth token' do
      get_package(package)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /api/v4/packages/npm/*package_name' do
    let(:package) { create(:npm_package, project: project, name: "@#{project.full_path}") }

    context 'a public project' do
      it 'returns the package info without oauth token' do
        get_package(package)

        expect_a_valid_package_response
      end
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package that requires auth'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package that requires auth'

      it 'denies request when not enough permissions' do
        project.add_guest(user)

        get_package_with_token(package)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      get_package(package)

      expect(response).to have_gitlab_http_status(403)
    end

    context 'project name is different from a package name' do
      let(:package) { create(:npm_package, project: project) }

      it 'rejects request' do
        get_package(package)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def get_package(package, params = {})
      get api("/packages/npm/#{package.name}"), params: params
    end

    def get_package_with_token(package, params = {})
      get_package(package, params.merge(access_token: token.token))
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package) { create(:npm_package, project: project, name: "@#{project.full_path}") }
    let(:package_file) { package.package_files.first }

    context 'a public project' do
      it 'returns the file' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns the file' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(403)
      end

      it 'denies download when no private token' do
        get_file(package_file)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    it 'rejects request if feature is not in the license' do
      stub_licensed_features(packages: false)

      get_file(package_file)

      expect(response).to have_gitlab_http_status(403)
    end

    def get_file(package_file, params = {})
      get api("/projects/#{project.id}/packages/npm/" \
              "#{package_file.package.name}/-/#{package_file.file_name}"), params: params
    end

    def get_file_with_token(package_file, params = {})
      get_file(package_file, params.merge(access_token: token.token))
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    context 'when params are correct' do
      context 'unscoped package' do
        let(:package_name) { project.path }
        let(:params) { upload_params(package_name) }

        it 'denies the request with 400 error' do
          expect { upload_package_with_token(package_name, params) }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'scoped package' do
        let(:package_name) { "@#{project.full_path}" }
        let(:params) { upload_params(package_name) }

        it 'creates npm package with file' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    def upload_package(package_name, params = {})
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params
    end

    def upload_package_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.token))
    end

    def upload_params(package_name)
      {
        name: package_name,
        versions: {
          '1.0.1' => {
            dist: {
              shasum: 'f572d396fae9206628714fb2ce00f72e94f2258f'
            }
          }
        },
        '_attachments' => {
          "#{package_name}-1.0.1.tgz" => {
            'data' => 'aGVsbG8K',
            'length' => 8
          }
        }
      }
    end
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(200)
    expect(response.content_type.to_s).to eq('application/json')
    expect(response).to match_response_schema('public_api/v4/packages/npm_package', dir: 'ee')
    expect(json_response['name']).to eq(package.name)
    expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee')
  end
end
