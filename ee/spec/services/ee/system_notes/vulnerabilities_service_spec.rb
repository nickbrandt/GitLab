# frozen_string_literal: true

require 'spec_helper'

describe EE::SystemNotes::VulnerabilitiesService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:author) { create(:user) }

  let(:noteable) { create(:vulnerability, project: project, state: state) }
  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_vulnerability_state' do
    subject { service.change_vulnerability_state }

    context 'state changed to dismissed' do
      let(:state) { 'dismissed' }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'closed' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("changed vulnerability status to dismissed")
      end
    end

    context 'state changed to resolved' do
      let(:state) { 'resolved' }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'closed' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("changed vulnerability status to resolved")
      end
    end

    context 'state changed to confirmed' do
      let(:state) { 'confirmed' }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'opened' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("changed vulnerability status to confirmed")
      end
    end
  end
end
