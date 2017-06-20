require 'spec_helper'

describe ApproverEntity do
  let(:user)     { create(:user) }
  let(:resource) { double('approver', user: user) }

  subject(:entity) { described_class.new(resource).as_json }

  it { is_expected.to include(user: UserEntity.represent(user).as_json) }
end
