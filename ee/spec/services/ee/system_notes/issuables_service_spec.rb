# frozen_string_literal: true

require 'spec_helper'

describe ::SystemNotes::IssuablesService do
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

  describe '#auto_resolve_prometheus_alert' do
    subject { service.auto_resolve_prometheus_alert }

    it_behaves_like 'a system note' do
      let(:action) { 'closed' }
    end

    it 'creates the expected system note' do
      expect(subject.note).to eq('automatically closed this issue because the alert resolved.')
    end
  end
end
