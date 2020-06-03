# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IssuablesService do
  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }

  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic, group: group) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#relate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { service.relate_issue(noteable_ref) }

    it_behaves_like 'a system note' do
      let(:action) { 'relate' }
    end

    context 'when issue marks another as related' do
      it 'sets the note text' do
        expect(subject.note).to eq "marked this issue as related to #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '#unrelate_issue' do
    let(:noteable_ref) { create(:issue) }

    subject { service.unrelate_issue(noteable_ref) }

    it_behaves_like 'a system note' do
      let(:action) { 'unrelate' }
    end

    context 'when issue relation is removed' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed the relation with #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '#change_weight_note' do
    context 'when weight changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: 4) }

      subject { service.change_weight_note }

      it_behaves_like 'a system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed weight to **4**"
      end
    end

    context 'when weight removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', weight: nil) }

      subject { service.change_weight_note }

      it_behaves_like 'a system note' do
        let(:action) { 'weight' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the weight'
      end
    end
  end

  describe '#change_health_status_note' do
    context 'when health_status changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: 'at_risk') }

      subject { service.change_health_status_note }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed health status to **at risk**"
      end
    end

    context 'when health_status removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: nil) }

      subject { service.change_health_status_note }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the health status'
      end
    end
  end

  describe '#publish_issue_to_status_page' do
    let_it_be(:noteable) { create(:issue, project: project) }

    subject { service.publish_issue_to_status_page }

    it_behaves_like 'a system note' do
      let(:action) { 'published' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'published this issue to the status page'
    end
  end

  describe '#change_iteration' do
    subject { service.change_iteration(iteration) }

    context 'for a project iteration' do
      let(:iteration) { create(:iteration, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'iteration' }
      end

      it_behaves_like 'a note with overridable created_at'

      context 'when iteration added' do
        it 'sets the note text' do
          reference = iteration.to_reference(format: :id)

          expect(subject.note).to eq "changed iteration to #{reference}"
        end
      end

      context 'when iteration removed' do
        let(:iteration) { nil }

        it 'sets the note text' do
          expect(subject.note).to eq 'removed iteration'
        end
      end
    end

    context 'for a group iteration' do
      let(:iteration) { create(:iteration, group: group) }

      it_behaves_like 'a system note' do
        let(:action) { 'iteration' }
      end

      it_behaves_like 'a note with overridable created_at'

      context 'when iteration added' do
        it 'sets the note text to use the iteration id' do
          expect(subject.note).to eq "changed iteration to #{iteration.to_reference(format: :id)}"
        end
      end

      context 'when iteration removed' do
        let(:iteration) { nil }

        it 'sets the note text' do
          expect(subject.note).to eq 'removed iteration'
        end
      end
    end
  end
end
