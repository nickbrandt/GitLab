require 'spec_helper'

describe MergeRequestBasicEntity do
  let(:project)  { create :empty_project }
  let(:resource) { create(:merge_request, source_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject(:entity) { described_class.new(resource, request: request).as_json }

  it 'exposes approvals' do
    approvals = MergeRequestApprovalsEntity
      .represent(resource, request: request)
      .as_json

    expect(entity[:approvals]).to eq(approvals)
  end
end
