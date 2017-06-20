require 'spec_helper'

describe MergeRequestBasicEntity do
  let(:project)  { create :empty_project }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'exposes approvals' do
    approvals = MergeRequestApprovalsEntity
      .represent(resource, request: request)
      .as_json

    expect(subject[:approvals]).to eq(approvals)
  end
end
