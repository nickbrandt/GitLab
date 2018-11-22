require 'spec_helper'

describe GitPushService do
  include RepoHelpers

  set(:user)     { create(:user) }
  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev)   { sample_commit.parent_id }
  let(:newrev)   { sample_commit.id }
  let(:ref)      { 'refs/heads/master' }

  context 'with pull project' do
    set(:project) { create(:project, :repository, :mirror) }

    subject do
      described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
    end

    context 'deleted branch' do
      let(:newrev) { blankrev }

      it 'handles when remote branch exists' do
        allow(project.repository).to receive(:commit).and_call_original
        allow(project.repository).to receive(:commit).with("master").and_return(nil)
        expect(project.repository).to receive(:commit).with("refs/remotes/upstream/master").and_return(sample_commit)

        subject.execute
      end
    end
  end
end
