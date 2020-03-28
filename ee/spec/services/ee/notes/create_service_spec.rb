# frozen_string_literal: true

require 'spec_helper'

describe Notes::CreateService do
  context 'notes for designs' do
    let_it_be(:design) { create(:design, :with_file) }
    let_it_be(:project) { design.project }
    let_it_be(:user) { project.owner }

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

      it 'sends a notification about this note', :sidekiq_might_not_need_inline do
        notifier = double
        allow(::NotificationService).to receive(:new).and_return(notifier)

        expect(notifier)
          .to receive(:new_note)
          .with have_attributes(noteable: design)

        service.execute
      end

      it 'correctly builds the position of the note' do
        note = service.execute

        expect(note.position.new_path).to eq(design.full_path)
        expect(note.position.old_path).to eq(design.full_path)
        expect(note.position.diff_refs).to eq(design.diff_refs)
      end

      context 'note with commands' do
        context 'for issues' do
          let(:issuable) { create(:issue, project: project, weight: 10) }
          let(:opts) { { noteable_type: 'Issue', noteable_id: issuable.id } }
          let(:note_params) { opts }

          it_behaves_like 'issuable quick actions' do
            let(:quick_actions) do
              [
                QuickAction.new(
                  action_text: '/weight 5',
                  expectation: ->(noteable, can_use_quick_action) {
                    expect(noteable.weight == 5).to eq(can_use_quick_action)
                  }
                ),
                QuickAction.new(
                  action_text: '/clear_weight',
                  expectation: ->(noteable, can_use_quick_action) {
                    if can_use_quick_action
                      expect(noteable.weight).to be_nil
                    else
                      expect(noteable.weight).not_to be_nil
                    end
                  }
                )
              ]
            end
          end
        end
      end
    end
  end
end
