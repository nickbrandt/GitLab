# frozen_string_literal: true

require 'spec_helper'

def saved_sessions
  session[Gitlab::WardenSession::KEY]
end

# user should be the user loggin in.
RSpec.shared_examples 'successful multi user login' do
  it 'saves the new user session' do
    expect(saved_sessions).to have_key(user.id)
  end

  it 'retains the warden session' do
    expect(session.keys).to include 'warden.user.user.key'
  end

  it 'logs in the correct user' do
    expect(session.dig('warden.user.user.key', 0, 0)).to eq user.id
  end

  it 'transparently set the current user ' do
    expect(controller.instance_variable_get(:@current_user)).to eq user
  end
end

RSpec.shared_examples 'failed multi user login' do
  it 'does not save a new user session' do
    expect(saved_sessions).to be_nil
  end

  it 'does not login a user' do
    expect(session.keys).not_to include 'warden.user.user.key'
  end

  it 'transparently set the current user ' do
    expect(controller.instance_variable_get(:@current_user)).to be_nil
  end
end

# user is the user that has logged out.
# logged_in_sessions refers to the number of signed in sessions after sign out.
# default to 1.
RSpec.shared_examples 'multi user logout session' do |logged_in_sessions = 1|
  it 'removes the warden session' do
    expect(session).not_to have_key 'warden.user.user.key'
  end

  it 'removes the saved warden session' do
    if logged_in_sessions > 1
      expect(saved_sessions).not_to have_key(user.id)
    else
      expect(session).not_to have_key(Gitlab::WardenSession::KEY)
    end
  end
end
