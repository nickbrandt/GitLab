# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::PushOptionsHandlerService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:source_branch) { 'fix' }
  let(:changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:service) { described_class.new(project, user, changes, push_options) }

  before do
    project.add_developer(user)
  end

  describe '`assignee` push option' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:assignees) { [user1, user2] }
    let(:assignee_options) { assignees.each_with_object({}) { |a, h| h[a.username] = 1 } }
    let(:push_options) { { create: true, assignee: assignee_options } }
    let(:last_mr) { MergeRequest.last }

    it 'allows setting multiple assignees' do
      service.execute

      expect(last_mr.assignees).to match_array(assignees)
    end
  end
end
