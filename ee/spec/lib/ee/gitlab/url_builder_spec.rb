# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe '.build' do
    context 'when passing a DesignManagement::Design' do
      it 'returns a proper URL to the raw (unresized) image' do
        design = build_stubbed(:design)

        url = described_class.build(design, ref: 'master')

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/design_management/designs/#{design.id}/master/raw_image"
      end

      it 'returns a proper URL to the resized image' do
        design = build_stubbed(:design)

        url = described_class.build(design, ref: 'master', size: 'small')

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/design_management/designs/#{design.id}/master/resized_image/small"
      end
    end

    context 'when passing an epic' do
      it 'returns a proper URL' do
        epic = build_stubbed(:epic, iid: 42)

        url = described_class.build(epic)

        expect(url).to eq "#{Settings.gitlab['url']}/groups/#{epic.group.full_path}/-/epics/#{epic.iid}"
      end
    end

    context 'when passing an epic note' do
      it 'returns a proper URL' do
        epic = create(:epic)
        note = build_stubbed(:note_on_epic, noteable: epic)

        url = described_class.build(note)

        expect(url).to eq "#{Settings.gitlab['url']}/groups/#{epic.group.full_path}/-/epics/#{epic.iid}#note_#{note.id}"
      end
    end
  end
end
