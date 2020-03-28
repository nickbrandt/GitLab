# frozen_string_literal: true

require 'spec_helper'

describe Notes::DestroyService do
  subject { described_class.new(note.project) }

  let(:note) { create(:note) }

  describe '#execute' do
    let(:analytics_mock) { instance_double('Analytics::RefreshCommentsData') }

    it 'invokes forced Analytics::RefreshCommentsData' do
      allow(Analytics::RefreshCommentsData).to receive(:for_note).with(note).and_return(analytics_mock)

      expect(analytics_mock).to receive(:execute).with(force: true)

      subject.execute(note)
    end
  end
end
