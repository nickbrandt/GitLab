require 'spec_helper'

describe MergeRequestApprovalsEntity do
  let(:project)  { create :empty_project }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'exposes approvals_required' do
    expect(subject[:approvals_required]).to be_a(Numeric)
  end

  it 'exposes approvals_left' do
    expect(subject[:approvals_left]).to be_a(Numeric)
  end

  it 'exposes approved_by' do
    expect(subject[:approved_by]).to be_a(Array)
  end

  it 'exposes suggested_approvers' do
    expect(subject[:suggested_approvers]).to be_a(Array)
  end

  it 'exposes user_can_approve' do
    expect(subject[:user_can_approve]).to be(resource.can_approve?(user))
  end

  it 'exposes user_has_approved' do
    expect(subject[:user_has_approved]).to be(resource.has_approved?(user))
  end
end
