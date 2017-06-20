require 'spec_helper'

describe ApproverEntity do
  let(:user)     { create(:user) }
  let(:resource) { double('approver', user: user) }

  subject do
    described_class.new(resource).as_json
  end

  it 'exposes user' do
    user_payload = UserEntity.represent(user).as_json

    expect(subject[:user]).to eq(user_payload)
  end
end
