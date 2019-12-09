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

shared_examples 'returns nuget service index' do |user_type, status, add_member = true|
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
  end
end
