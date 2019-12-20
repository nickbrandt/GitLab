# frozen_string_literal: true

require 'spec_helper'

describe API::NpmPackages do
  let(:group)   { create(:group) }
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:token)   { create(:oauth_access_token, scopes: 'api', resource_owner: user) }
  let(:job) { create(:ci_build, user: user) }

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)
  end

  shared_examples 'a package that requires auth' do
    it 'returns the package info with oauth token' do
      get_package_with_token(package)

      expect_a_valid_package_response
    end

    it 'returns the package info with job token' do
      get_package_with_job_token(package)

      expect_a_valid_package_response
    end

    it 'denies request without oauth token' do
      get_package(package)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /api/v4/packages/npm/*package_name' do
    let(:package) { create(:npm_package, project: project) }
    let!(:package_dependency_link1) { create(:packages_dependency_link, package: package, dependency_type: :dependencies) }
    let!(:package_dependency_link2) { create(:packages_dependency_link, package: package, dependency_type: :devDependencies) }
    let!(:package_dependency_link3) { create(:packages_dependency_link, package: package, dependency_type: :bundleDependencies) }
    let!(:package_dependency_link4) { create(:packages_dependency_link, package: package, dependency_type: :peerDependencies) }
    let!(:package_dependency_link5) { create(:packages_dependency_link, package: package, dependency_type: :deprecated) }

    context 'a public project' do
      it 'returns the package info without oauth token' do
        get_package(package)

        expect_a_valid_package_response
      end

      context 'project path with a dot' do
        let(:project) { create(:project, :public, namespace: group, path: 'foo.bar') }

        it 'returns the package info' do
          get_package(package)

          expect_a_valid_package_response
        end
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

    def get_package(package, params = {})
      get api("/packages/npm/#{package.name}"), params: params
    end

    def get_package_with_token(package, params = {})
      get_package(package, params.merge(access_token: token.token))
    end

    def get_package_with_job_token(package, params = {})
      get_package(package, params.merge(job_token: job.token))
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package) { create(:npm_package, project: project) }
    let(:package_file) { package.package_files.first }

    shared_examples 'a package file that requires auth' do
      it 'returns the file with an access token' do
        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'returns the file with a job token' do
        get_file_with_job_token(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end

      it 'denies download with no token' do
        get_file(package_file)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'a public project' do
      it 'returns the file with no token needed' do
        get_file(package_file)

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type.to_s).to eq('application/octet-stream')
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package file that requires auth'

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        get_file_with_token(package_file)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'internal project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package file that requires auth'
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

    def get_file_with_job_token(package_file, params = {})
      get_file(package_file, params.merge(job_token: job.token))
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    context 'when params are correct' do
      context 'invalid package record' do
        context 'unscoped package' do
          let(:package_name) { 'my_unscoped_package' }
          let(:params) { upload_params(package_name) }

          it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
            expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

            expect(response).to have_gitlab_http_status(400)
          end
        end

        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }
          let(:params) { upload_params(package_name) }

          it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
            expect { upload_package_with_token(package_name, params) }
              .not_to change { project.packages.count }

            expect(response).to have_gitlab_http_status(400)
          end
        end
      end

      context 'scoped package' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name) }

        it 'creates npm package with file with access token' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'creates npm package with file with job token' do
          expect { upload_package_with_job_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(200)
        end

        context 'with an authenticated job token' do
          let!(:job) { create(:ci_build, user: user) }

          before do
            Grape::Endpoint.before_each do |endpoint|
              expect(endpoint).to receive(:current_authenticated_job) { job }
            end
          end

          after do
            Grape::Endpoint.before_each nil
          end

          it 'creates the package metadata' do
            upload_package_with_token(package_name, params)

            expect(response).to have_gitlab_http_status(200)
            expect(project.reload.packages.find(json_response['id']).build_info.pipeline).to eq job.pipeline
          end
        end
      end

      context 'package creation fails' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name) }

        it 'returns an error if the package already exists' do
          create(:npm_package, project: project, version: '1.0.1', name: "@#{group.path}/my_package_name")
          expect { upload_package_with_token(package_name, params) }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'with dependencies' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name, 'npm/payload_with_duplicated_packages.json') }

        it 'creates npm package with file and dependencies' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::Dependency.count}.by(4)
            .and change { Packages::DependencyLink.count}.by(7)

          expect(response).to have_gitlab_http_status(200)
        end

        context 'with existing dependencies' do
          before do
            name = "@#{group.path}/existing_package"
            upload_package_with_token(name, upload_params(name, 'npm/payload_with_duplicated_packages.json'))
          end

          it 'reuses them' do
            expect { upload_package_with_token(package_name, params) }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
              .and not_change { Packages::Dependency.count}
              .and change { Packages::DependencyLink.count}.by(7)
          end
        end
      end
    end

    def upload_package(package_name, params = {})
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params
    end

    def upload_package_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.token))
    end

    def upload_package_with_job_token(package_name, params = {})
      upload_package(package_name, params.merge(job_token: job.token))
    end

    def upload_params(package_name, file = 'npm/payload.json')
      JSON.parse(
        fixture_file(file, dir: 'ee')
          .gsub('@root/npm-test', package_name))
    end
  end

  def expect_a_valid_package_response
    expect(response).to have_gitlab_http_status(200)
    expect(response.content_type.to_s).to eq('application/json')
    expect(response).to match_response_schema('public_api/v4/packages/npm_package', dir: 'ee')
    expect(json_response['name']).to eq(package.name)
    expect(json_response['versions'][package.version]).to match_schema('public_api/v4/packages/npm_package_version', dir: 'ee')
    NpmPackagePresenter::NPM_VALID_DEPENDENCY_TYPES.each do |dependency_type|
      expect(json_response.dig('versions', package.version, dependency_type.to_s)).to be_any
    end
  end
end
