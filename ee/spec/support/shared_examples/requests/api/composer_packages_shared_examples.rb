# frozen_string_literal: true

RSpec.shared_examples 'process Composer api request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      group.send("add_#{user_type}", user) if add_member && user_type != :anonymous
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'rejects Composer access with unknown group id' do
  context 'with an unknown group' do
    let(:group) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'process Composer api request', :anonymous, :not_found
    end

    context 'as authenticated user' do
      subject { get api(url), headers: build_basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process Composer api request', :anonymous, :not_found
    end
  end
end

RSpec.shared_examples 'rejects Composer packages access with packages features disabled' do
  context 'with packages features disabled' do
    before do
      stub_licensed_features(packages: false)
    end

    it_behaves_like 'process Composer api request', :anonymous, :forbidden
  end
end

RSpec.shared_examples 'rejects Composer access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { double(id: non_existing_record_id) }

    context 'as anonymous' do
      it_behaves_like 'process PyPi api request', :anonymous, :not_found
    end

    context 'as authenticated user' do
      subject { get api(url), headers: build_basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process PyPi api request', :anonymous, :not_found
    end
  end
end
