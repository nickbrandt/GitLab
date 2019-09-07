# frozen_string_literal: true
require 'spec_helper'

describe API::ComposerPackages do
  let(:user) {create(:user)}
  let(:group) {create(:group, name: 'ochorocho')}
  let(:project) {create(:project, namespace: group, name: 'gitlab-composer')}
  let!(:package) {create(:composer_package, project: project, name: "#{group.name}/#{project.name}")}

  let(:token) {create(:oauth_access_token, scopes: 'api', resource_owner: user)}
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:headers_with_token) { { 'Private-Token' => personal_access_token.token } }
  let(:sha_empty) {'52f6fd0d18e08b13132da4adaeb804766d6e0bf3'}

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)
  end

  describe 'GET /namespace/*namespace/-/packages/composer/packages.json' do
    let(:sha) {'d8d023b6259f0e9a7f2fd11df293718ba3d799ec'}

    it 'returns the package includes on namespace endpoint' do
      get_namespace_packages
      json = JSON.parse(response.body)

      expect(json['includes'].first[1]['sha1']).to eq(sha_empty)
      expect_a_valid_package_response
    end

    it 'returns the package includes on namespace endpoint with token' do
      get_namespace_packages_with_token
      json = JSON.parse(response.body)

      expect(json['includes'].first[1]['sha1']).to eq(sha)
      expect_a_valid_package_response
    end

    def get_namespace_packages(params = {})
      get api("/namespace/#{group.id}/-/packages/composer/packages.json"), params: params
    end

    def get_namespace_packages_with_token(params = {})
      get_namespace_packages(params.merge(access_token: token.token))
    end
  end

  describe 'GET /namespace/*namespace/-/packages/composer/include/all$*sha.json' do
    let(:sha) {'f4052b58b0d2b9f33c5c62c1b8a2f0273fec5da4'}

    it 'returns the packages info on empty namespace endpoint' do
      get_namespace_packages_includes(sha_empty)
      json = JSON.parse(response.body)

      expect(json['packages']).to be_empty
      expect_a_valid_package_response
    end

    it 'returns the packages info on namespace endpoint with token' do
      get_namespace_packages_includes_with_token(sha)
      json = JSON.parse(response.body)
      version = upload_params(package.name)

      expect(json['packages'].first[0]).to eq("#{group.name}/#{project.name}")
      expect(json['packages']["#{group.name}/#{project.name}"][version[:version]]).not_to be_blank
      expect_a_valid_package_response
    end

    it 'returns 404 NotFound if path json does not exist' do
      get_namespace_packages_includes("non-existing-sha-value")

      expect(response).to have_gitlab_http_status(404)
    end

    def get_namespace_packages_includes(sha, params = {})
      get api("/namespace/#{group.id}/-/packages/composer/include/all$#{sha}.json"), params: params
    end

    def get_namespace_packages_includes_with_token(sha, params = {})
      get_namespace_packages_includes(sha, params.merge(access_token: token.token))
    end
  end

  describe 'GET /packages/composer/packages.json' do
    let(:sha) {'7716160b6c75020445aed3c1c16cf0992fce461a'}

    it 'returns the packages info on instance endpoint' do
      get_instance_packages
      json = JSON.parse(response.body)

      expect(json['includes'].first[1]['sha1']).to eq(sha_empty)
      expect_a_valid_package_response
    end

    it 'returns the packages info on instance endpoint with token' do
      get_instance_packages_with_token
      json = JSON.parse(response.body)

      expect(json['includes'].first[1]['sha1']).to eq(sha)
      expect_a_valid_package_response
    end

    context 'package name not matching namespace name' do
      let(:package) {create(:composer_package, project: project, name: "not-matching/#{project.name}")}

      it 'returns empty packages info on instance endpoint with token' do
        get_instance_packages_with_token
        json = JSON.parse(response.body)

        expect(json['includes'].first[1]['sha1']).to eq(sha_empty)
        expect_a_valid_package_response
      end
    end

    def get_instance_packages(params = {})
      get api("/packages/composer/packages.json"), params: params
    end

    def get_instance_packages_with_token(params = {})
      get_instance_packages(params.merge(access_token: token.token))
    end
  end

  describe 'GET /packages/composer/include/all$*sha.json' do
    let(:sha) {'d9713aa862ce1516bf8de840d89def833535bac9'}

    it 'returns the package info/includes on instance endpoint' do
      get_instance_packages_includes(sha_empty)
      json = JSON.parse(response.body)

      expect(json['packages']).to be_empty
      expect_a_valid_package_response
    end

    it 'returns the package info/includes on instance endpoint with token' do
      get_instance_packages_includes_with_token(sha)
      json = JSON.parse(response.body)

      expect(json['packages'].first[0]).to eq("#{group.name}/#{project.name}")
      expect_a_valid_package_response
    end

    it 'returns 404 NotFound if path json does not exist' do
      get_instance_packages_includes("non-existing-sha-value")

      expect(response).to have_gitlab_http_status(404)
    end

    def get_instance_packages_includes(sha, params = {})
      get api("/packages/composer/include/all$#{sha}.json"), params: params
    end

    def get_instance_packages_includes_with_token(sha, params = {})
      get_instance_packages_includes(sha, params.merge(access_token: token.token))
    end
  end

  describe 'PUT /:id/packages/composer/:package_name' do
    context 'when params are correct' do
      let(:params) {upload_params(package.name).to_json}

      it 'returns 401 NotAuthorized' do
        upload_package(package.name, params)
        expect(response).to have_gitlab_http_status(401)
      end

      it 'creates composer package with files' do
        # Clear packages because of implemented auto-update function
        # This will remove 2 files and 2 associactions max
        project.packages.destroy_all # rubocop:disable Cop/DestroyAll

        expect {upload_package_with_token(package.name, params, headers_with_token)}
            .to change {project.packages.count}.by(1)
                    .and change {Packages::PackageFile.count}.by(2)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    def upload_package(package_name, params, headers = {})
      put api("/projects/#{project.id}/packages/composer/#{package_name.sub('/', '%2f')}"), params: JSON.parse(params), as: :json, headers: headers
    end

    def upload_package_with_token(package_name, params, headers = {})
      upload_package(package_name, params, headers)
    end
  end

  describe 'GET /:id/packages/composer/*package_name/-/*file_name' do
    context 'private project' do
      before do
        project.update!(visibility_level: 0)
      end

      it 'denies request when not enough permissions' do
        get_package(package)
        expect(response).to have_gitlab_http_status(404)
      end

      it 'allows request when enough permissions' do
        get_package_with_token(package)

        expect_valid_download
      end
    end

    context 'public project' do
      before do
        project.update!(visibility_level: 20)
      end

      it 'allows request' do
        get_package(package)

        expect_valid_download
      end
    end

    def get_package(package, params = {})
      get api("/projects/#{project.id}/packages/composer/#{package.name}/-/#{package.package_files.first.file_name}"), params: params
    end

    def get_package_with_token(package, params = {})
      get_package(package, params.merge(access_token: token.token))
    end

    def expect_valid_download
      params = upload_params(package.name)
      filename = params['attachments'][0]['filename']

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type.to_s).to eq('application/octet-stream')
      expect(response.headers['Content-Disposition']).to include("filename=\"#{filename}\"")
    end
  end

  def upload_params(package_name)
    {
        name: package_name,
        version: '2.0.0',
        version_data: JSON.parse(File.read('ee/spec/fixtures/composer/version-2.0.0.json')).first[1],
        shasum: '',
        'attachments' => [
            {
                'contents' => Base64.encode64('aGVsbG8K'),
                'filename' => 'ochorocho-gitlab-composer-2.0.0-19c3ec.tar',
                'length' => 8
            },
            {
                'contents' => Base64.encode64('aGVsbG8K'),
                'filename' => 'version-dev-develop.json',
                'length' => 8
            }
        ]
    }
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(200)
    expect(response.content_type.to_s).to eq('application/json')
    expect(response.body).to match_schema('public_api/v4/packages/composer-repository-schema', dir: 'ee')
  end
end
