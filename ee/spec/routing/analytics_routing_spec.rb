# frozen_string_literal: true

require 'spec_helper'

describe 'Analytics' do
  include RSpec::Rails::RequestExampleGroup
  include Warden::Test::Helpers

  it 'redirects to sign_in if user is not authenticated' do
    expect(get('/-/analytics')).to redirect_to('/users/sign_in')
  end
end
