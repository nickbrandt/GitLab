require 'spec_helper'

describe MergeRequestApprovalsEntity do
  let(:project)  { create(:empty_project, approvals_before_merge: 2) }
  let(:user)     { create(:user) }
  let(:other_user) { create(:user) }
  let(:resource) { create(:merge_request, source_project: project) }
  let(:request) { double('request', current_user: user) }

  subject(:entity) { described_class.new(resource, request: request).as_json }

  before do
    project.add_master(user)

    resource.approvals.create!(user: user)
    resource.approvers.create!(user: other_user)
  end

  it 'exposes approvals properties' do
    is_expected.to eq(
      approvals_required: 2,
      approvals_left: 1,
      approved_by: [{ user: UserEntity.represent(user).as_json }],
      suggested_approvers: [UserEntity.represent(other_user).as_json],
      user_can_approve: false,
      user_has_approved: true
    )
  end
end
