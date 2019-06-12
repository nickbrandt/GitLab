# frozen_string_literal: true

require 'spec_helper'

describe Notes::CreateService do
  context 'notes for designs' do
    set(:design) { create(:design, :with_file) }
    set(:project) { design.project }
    set(:user) { project.owner }

    subject(:service) { described_class.new(project, user, opts) }

    describe "#execute" do
      let(:opts) do
        {
          type: 'DiffNote',
          noteable: design,
          note: "A message",
          position: {
            old_path: design.full_path,
            new_path: design.full_path,
            position_type: 'image',
            width: '100',
            height: '100',
            x: '50',
            y: '50',
            base_sha: design.diff_refs.base_sha,
            start_sha: design.diff_refs.base_sha,
            head_sha: design.diff_refs.head_sha
          }
        }
      end

      it 'can create diff notes for designs' do
        note = service.execute

        expect(note).to be_a(DiffNote)
        expect(note).to be_persisted
        expect(note.noteable).to eq(design)
      end

      it 'correctly builds the position of the note' do
        note = service.execute

        expect(note.position.new_path).to eq(design.full_path)
        expect(note.position.old_path).to eq(design.full_path)
        expect(note.position.diff_refs).to eq(design.diff_refs)
      end
    end
  end
end
