# frozen_string_literal: true

RSpec.shared_examples 'process PyPi api request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'rejects PyPI access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'process PyPi api request', :anonymous, :unauthorized
    end

    context 'as authenticated user' do
      subject { get api(url), headers: build_basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process PyPi api request', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'rejects PyPI packages access with packages features disabled' do
  context 'with packages features disabled' do
    before do
      stub_licensed_features(packages: false)
    end

    it_behaves_like 'process PyPi api request', :anonymous, :forbidden
  end
end
