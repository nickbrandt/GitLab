# frozen_string_literal: true

require "spec_helper"

describe ProtectedBranches::CreateService do
  include ProjectForksHelper

  let(:source_project) { create(:project) }
  let(:target_project) { fork_project(source_project, user, repository: true) }

  let(:user) { source_project.owner }

  let(:params) do
    {
      name: "feature",
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  describe "#execute" do
    subject(:service) { described_class.new(target_project, user, params) }

    before do
      target_project.add_user(user, :developer)
    end

    context "when there are open merge requests" do
      let!(:merge_request) do
        create(:merge_request,
          source_project: source_project,
          target_project: target_project,
          discussion_locked: false
        )
      end

      it "calls MergeRequest::SyncCodeOwnerApprovalRules to update open MRs" do
        expect(::MergeRequests::SyncCodeOwnerApprovalRules).to receive(:new).with(merge_request).and_call_original
        expect { service.execute }.to change(ProtectedBranch, :count).by(1)
      end

      context "when the branch is a wildcard" do
        %w(*ture *eatur* feat*).each do |wildcard|
          before do
            params[:name] = wildcard
          end

          it "calls MergeRequest::SyncCodeOwnerApprovalRules to update open MRs for #{wildcard}" do
            expect(::MergeRequests::SyncCodeOwnerApprovalRules).to receive(:new).with(merge_request).and_call_original
            expect { service.execute }.to change(ProtectedBranch, :count).by(1)
          end
        end
      end
    end
  end
end
