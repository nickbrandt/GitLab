# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestResetApprovalsWorker do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  subject { described_class.new }

  describe '#perform' do
    let(:newrev) { "789012" }
    let(:ref)    { "refs/heads/test" }

    def perform
      subject.perform(project.id, user.id, ref, newrev)
    end

    it 'executes MergeRequests::RefreshService with expected values' do
      expect_next_instance_of(EE::MergeRequests::ResetApprovalsService, project, user) do |refresh_service|
        expect(refresh_service).to receive(:execute).with(ref, newrev)
      end

      perform
    end
  end
end
