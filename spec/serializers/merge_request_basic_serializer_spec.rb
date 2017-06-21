require 'spec_helper'

describe MergeRequestBasicSerializer do
  let(:resource) { create(:merge_request) }
  let(:user)     { create(:user) }

  subject(:entity) { described_class.new(current_user: user).represent(resource) }

  it { is_expected.to include(:merge_status) }
end
