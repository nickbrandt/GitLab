# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatMessage::MergeMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
          name: 'Test User',
          username: 'test.user',
          avatar_url: 'http://someavatar.com'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',

      object_attributes: {
        title: "Merge Request title\nSecond line",
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
        state: 'opened',
        description: 'merge request description',
        source_branch: 'source_branch',
        target_branch: 'target_branch'
      }
    }
  end

  context 'approved' do
    before do
      args[:object_attributes][:action] = 'approved'
    end

    it 'returns a message regarding completed approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) approved <http://somewhere.com/merge_requests/100|!100 *Merge Request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'unapproved' do
    before do
      args[:object_attributes][:action] = 'unapproved'
    end

    it 'returns a message regarding revocation of completed approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) unapproved <http://somewhere.com/merge_requests/100|!100 *Merge Request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'approval' do
    before do
      args[:object_attributes][:action] = 'approval'
    end

    it 'returns a message regarding added approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) added their approval to <http://somewhere.com/merge_requests/100|!100 *Merge Request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end

  context 'unapproval' do
    before do
      args[:object_attributes][:action] = 'unapproval'
    end

    it 'returns a message regarding revoking approval of merge requests' do
      expect(subject.pretext).to eq(
        'Test User (test.user) removed their approval from <http://somewhere.com/merge_requests/100|!100 *Merge Request title*> '\
        'in <http://somewhere.com|project_name>')
      expect(subject.attachments).to be_empty
    end
  end
end
