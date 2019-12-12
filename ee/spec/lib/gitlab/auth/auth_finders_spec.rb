# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::AuthFinders do
  include described_class

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end
  let(:request) { ActionDispatch::Request.new(env)}
  let(:params) { request.params }

  def set_param(key, value)
    request.update_param(key, value)
  end

  shared_examples 'find user from job token' do
    context 'when route is allowed to be authenticated' do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      it "returns an Unauthorized exception for an invalid token" do
        set_token('invalid token')

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      it "return user if token is valid" do
        set_token(job.token)

        expect(subject).to eq(user)
        expect(@current_authenticated_job).to eq job
      end
    end
  end

  describe '#validate_access_token!' do
    subject { validate_access_token! }

    context 'with a job token' do
      let(:route_authentication_setting) { { job_token_allowed: true } }
      let(:job) { create(:ci_build, user: user) }

      before do
        env['HTTP_AUTHORIZATION'] = "Bearer #{job.token}"
        find_user_from_bearer_token
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'without a job token' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      before do
        personal_access_token.revoke!
        allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      end

      it 'delegates the logic to super' do
        expect { subject }.to raise_error(Gitlab::Auth::RevokedError)
      end
    end
  end

  describe '#find_user_from_bearer_token' do
    let(:job) { create(:ci_build, user: user) }
    subject { find_user_from_bearer_token }

    context 'when the token is passed as an oauth token' do
      def set_token(token)
        env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
      end

      context 'with a job token' do
        it_behaves_like 'find user from job token'
      end

      context 'with oauth token' do
        let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
        let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api').token }

        before do
          set_token(token)
        end

        it { is_expected.to eq user }
      end
    end

    context 'with a personal access token' do
      let(:pat) { create(:personal_access_token, user: user) }
      let(:token) { pat.token }

      before do
        env[described_class::PRIVATE_TOKEN_HEADER] = pat.token
      end

      it { is_expected.to eq user }
    end
  end

  describe '#find_user_from_job_token' do
    let(:job) { create(:ci_build, user: user) }
    subject { find_user_from_job_token }

    shared_examples 'job token disabled' do
      context 'when route is not allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: false } }

        it "sets current_user to nil" do
          set_token(job.token)
          allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(true)

          expect(subject).to be_nil
        end
      end
    end

    context 'when the job token is in the headers' do
      def set_token(token)
        env[described_class::JOB_TOKEN_HEADER] = token
      end

      it_behaves_like 'find user from job token'
      it_behaves_like 'job token disabled'
    end

    context 'when the job token is in the params' do
      def set_token(token)
        set_param(described_class::JOB_TOKEN_PARAM, token)
      end

      it_behaves_like 'find user from job token'
      it_behaves_like 'job token disabled'
    end
  end
end
