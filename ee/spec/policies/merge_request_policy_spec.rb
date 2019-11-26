require 'spec_helper'

describe MergeRequestPolicy do
  include ProjectForksHelper

  let(:guest) { create(:user) }
  let(:developer) { create(:user) }
  let(:maintainer) { create(:user) }

  let(:fork_guest) { create(:user) }
  let(:fork_developer) { create(:user) }
  let(:fork_maintainer) { create(:user) }

  let(:project) { create(:project, :public) }
  let(:forked_project) { fork_project(project) }

  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:fork_merge_request) { create(:merge_request, author: fork_developer, source_project: forked_project, target_project: project) }

  before do
    project.add_guest(guest)
    project.add_developer(developer)
    project.add_maintainer(maintainer)

    forked_project.add_guest(fork_guest)
    forked_project.add_developer(fork_guest)
    forked_project.add_maintainer(fork_maintainer)
  end

  def policy_for(user)
    described_class.new(user, merge_request)
  end

  context 'for a merge request within the same project' do
    context 'when overwriting approvers is disabled on the project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(maintainer)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the project' do
      it 'allows only project developers and above to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'allows project developers and above' do
      it 'to approve the merge request' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end
  end

  context 'for a merge request from a fork' do
    let(:merge_request) { fork_merge_request }

    context 'when overwriting approvers is disabled on the target project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(maintainer)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is disabled on the source project' do
      before do
        forked_project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'has no effect - project developers and above, as well as the author, can update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the target project' do
      it 'allows project developers and above, as well as the author, to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'allows project developers and above' do
      it 'to approve the merge requests' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end
  end
end
