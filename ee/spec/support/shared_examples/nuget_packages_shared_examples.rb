# frozen_string_literal: true

shared_examples 'rejects nuget packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    if status == :unauthorized
      it 'has the correct response header' do
        subject

        expect(response.headers['Www-Authenticate: Basic realm']).to eq 'GitLab Nuget Package Registry'
      end
    end
  end
end

shared_examples 'process nuget service index request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'returns a valid json response' do
      subject

      expect(response.content_type.to_s).to eq('application/json')
      expect(json_response).to be_a(Hash)
    end

    it 'returns a valid nuget service index json' do
      subject

      expect(json_response).to match_schema('public_api/v4/packages/nuget/service_index', dir: 'ee')
    end

    context 'with invalid format' do
      let(:url) { "/projects/#{project.id}/packages/nuget/index.xls" }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end

shared_examples 'process nuget workhorse authorization' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'has the proper content type' do
      subject

      expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    context 'with a request that bypassed gitlab-workhorse' do
      let(:headers) do
        build_basic_auth_header(user.username, personal_access_token.token)
          .merge(workhorse_header)
          .tap { |h| h.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER) }
      end

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'returning response status', :error
    end
  end
end

shared_examples 'process nuget upload' do |user_type, status, add_member = true|
  shared_examples 'creates nuget package files' do
    it 'creates package files' do
      expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package_file = project.packages.last.package_files.reload.last
      expect(package_file.file_name).to eq('package.nupkg')
      expect(package_file.file_type).to eq(0)
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    context 'with object storage disabled' do
      context 'without a file from workhorse' do
        let(:params) { { file: nil } }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with correct params' do
        it_behaves_like 'creates nuget package files'
        it_behaves_like 'a gitlab tracking event', described_class.name, 'push_package'
      end
    end

    context 'with object storage enabled' do
      context 'and direct upload enabled' do
        let!(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end
        let(:tmp_object) do
          fog_connection.directories.new(key: 'packages').files.create(
            key: "tmp/uploads/#{file_name}",
            body: 'content'
          )
        end
        let(:fog_file) { fog_to_uploaded_file(tmp_object) }
        let(:params) { { file: fog_file, 'file.remote_id' => file_name } }

        it_behaves_like 'creates nuget package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) do
              {
                file: fog_file,
                'file.remote_id' => remote_id
              }
            end

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      it_behaves_like 'background upload schedules a file migration'
    end
  end
end

shared_examples 'rejects nuget access with invalid project id' do
  context 'with a project id with invalid integers' do
    using RSpec::Parameterized::TableSyntax

    let(:project) { OpenStruct.new(id: id) }

    where(:id, :status) do
      '/../'       | :unauthorized
      ''           | :not_found
      '%20'        | :unauthorized
      '%2e%2e%2f'  | :unauthorized
      'NaN'        | :unauthorized
      00002345     | :unauthorized
      'anything25' | :unauthorized
    end

    with_them do
      it_behaves_like 'rejects nuget packages access', :anonymous, params[:status]
    end
  end
end

shared_examples 'rejects nuget access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'rejects nuget packages access', :anonymous, :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: build_basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'rejects nuget packages access', :anonymous, :not_found
    end
  end
end
