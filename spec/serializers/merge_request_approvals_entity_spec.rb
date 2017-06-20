require 'spec_helper'

describe MergeRequestApprovalsEntity do
  let(:project)  { create(:empty_project, approvals_before_merge: 2) }
  let(:user)     { create(:user) }
  let(:other_user)     { create(:user) }
  let(:resource) { create(:merge_request, source_project: project) }
  let(:request) { double('request', current_user: user) }

  subject(:entity) { described_class.new(resource, request: request).as_json }

  before do
    project.add_master(user)

    resource.approvals.create(user: user)
    resource.approvers.create(user: other_user)
  end

  it 'exposes approvals properties' do
    expect(entity[:approvals_required]).to eq(2)
    expect(entity[:approvals_left]).to eq(1)
    expect(entity[:approved_by].to_json).to eq([user: UserEntity.represent(user)].to_json)
    expect(entity[:suggested_approvers].to_json).to eq([UserEntity.represent(other_user)].to_json)
    expect(entity[:user_can_approve]).to eq(resource.can_approve?(user))
    expect(entity[:user_has_approved]).to eq(resource.has_approved?(user))
  end
end
