# frozen_string_literal: true

require 'spec_helper'

describe Issues::ZoomLinkService do
  set(:user) { create(:user) }
  set(:issue) { create(:issue) }

  let(:project) { issue.project }
  let(:service) { described_class.new(issue, user) }
  let(:zoom_link) { 'https://zoom.us/j/123456789' }

  before do
    project.add_reporter(user)
  end

  shared_context '"added" Zoom meeting' do
    before do
      create(:zoom_meeting, issue: issue)
    end
  end

  shared_context '"removed" zoom meetings' do
    before do
      create(:zoom_meeting, issue: issue, issue_status: :removed)
      create(:zoom_meeting, issue: issue, issue_status: :removed)
    end
  end

  shared_context 'insufficient permissions' do
    before do
      project.add_guest(user)
    end
  end

  describe '#add_link' do
    shared_examples 'can add meeting' do
      it 'appends the link zoom_meetings' do
        expect(result).to be_success
        expect(result.payload[:zoom_meetings].map(&:url))
          .to include(zoom_link)
      end

      it 'tracks the add event' do
        expect(Gitlab::Tracking).to receive(:event)
          .with('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
        result
      end

      it 'tracks the add event' do
        expect(Gitlab::Tracking).to receive(:event)
          .with('IncidentManagement::ZoomIntegration', 'add_zoom_meeting', label: 'Issue ID', value: issue.id)
        result
      end
    end

    shared_examples 'cannot add meeting' do
      it 'cannot add the meeting' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to add a Zoom meeting')
      end
    end

    subject(:result) { service.add_link(zoom_link) }

    context 'without existing Zoom meeting' do
      include_examples 'can add meeting'

      context 'with invalid Zoom meeting' do
        let(:zoom_link) { 'https://not-zoom.link' }

        include_examples 'cannot add meeting'
      end

      context 'with insufficient permissions' do
        include_context 'insufficient permissions'
        include_examples 'cannot add meeting'
      end
    end

    context 'with "added" Zoom meeting' do
      include_context '"added" Zoom meeting'
      include_examples 'cannot add meeting'
    end
  end

  describe '#can_add_link?' do
    subject { service.can_add_link? }

    context 'without Zoom link' do

      it { is_expected.to eq(true) }

      context 'with insufficient permissions' do
        include_context 'insufficient permissions'

        it { is_expected.to eq(false) }
      end
    end

    context 'with Zoom meeting in the issue description' do
      include_context  '"added" Zoom meeting'

      it { is_expected.to eq(false) }
    end
  end

  describe '#remove_link' do
    shared_examples 'cannot remove meeting' do
      it 'cannot remove the meeting' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to remove a Zoom meeting')
      end
    end

    shared_examples 'can remove meeting' do
      it 'can remove the meeting' do
        expect(result).to be_success
        expect(result.payload[:zoom_meetings].filter { |z| z.issue_status == 1 })
        .to be_empty
      end
    end

    subject(:result) { service.remove_link }

    context 'with Zoom meeting' do
      include_context '"added" Zoom meeting'

      context 'removes the link' do
        include_examples 'can remove meeting'

        it 'tracks the remove event' do
          expect(Gitlab::Tracking).to receive(:event)
          .with('IncidentManagement::ZoomIntegration', 'remove_zoom_meeting', label: 'Issue ID', value: issue.id)
          result
        end
      end

      context 'with insufficient permissions' do
        include_context 'insufficient permissions'
        include_examples 'cannot remove meeting'
      end
    end

    context 'without "added" Zoom meeting' do
      include_context '"removed" zoom meetings'
      include_examples 'cannot remove meeting'
    end
  end

  describe '#can_remove_link?' do
    subject { service.can_remove_link? }

    context 'without Zoom meeting' do
      it { is_expected.to eq(false) }
    end

    context 'with only "removed" zoom meetings' do
      include_context '"removed" zoom meetings'
      it { is_expected.to eq(false) }
    end

    context 'with "added" Zoom meeting' do
      include_context '"added" Zoom meeting'
      it { is_expected.to eq(true) }

      context 'with "removed" zoom meetings' do
        include_context '"removed" zoom meetings'
        it { is_expected.to eq(true) }
      end

      context 'with insufficient permissions' do
        include_context 'insufficient permissions'
        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#parse_link' do
    subject { service.parse_link(description) }

    context 'with valid Zoom links' do
      where(:description) do
        [
          'Some text https://zoom.us/j/123456789 more text',
          'Mixed https://zoom.us/j/123456789 http://example.com',
          'Multiple link https://zoom.us/my/name https://zoom.us/j/123456789'
        ]
      end

      with_them do
        it { is_expected.to eq('https://zoom.us/j/123456789') }
      end
    end

    context 'with invalid Zoom links' do
      where(:description) do
        [
          nil,
          '',
          'Text only',
          'Non-Zoom http://example.com',
          'Almost Zoom http://zoom.us'
        ]
      end

      with_them do
        it { is_expected.to eq(nil) }
      end
    end
  end
end
