# frozen_string_literal: true

RSpec.shared_context 'exclusive labels creation' do
  def create_label(title)
    if parent.is_a?(Group)
      create(:group_label, group: parent, title: title)
    else
      create(:label, project: parent, title: title)
    end
  end

  before do
    parent.add_developer(user)
  end
end

RSpec.shared_examples 'new issuable with scoped labels' do
  include_context 'exclusive labels creation' do
    context 'scoped labels are avaialble' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      it 'adds only last selected exclusive scoped label' do
        label1 = create_label('label1')
        label2 = create_label('key::label1')
        label3 = create_label('key::label2')
        label4 = create_label('key::label3')

        issuable = described_class.new(
          parent, user, title: 'test', label_ids: [label1.id, label3.id, label4.id, label2.id]
        ).execute

        expect(issuable.labels).to match_array([label1, label2])
      end
    end

    context 'scoped labels are not available' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      it 'adds all scoped labels' do
        label1 = create_label('label1')
        label2 = create_label('key::label1')
        label3 = create_label('key::label2')
        label4 = create_label('key::label3')

        issuable = described_class.new(
          parent, user, title: 'test', label_ids: [label1.id, label3.id, label4.id, label2.id]
        ).execute

        expect(issuable.labels).to match_array([label1, label2, label3, label4])
      end
    end
  end
end

RSpec.shared_examples 'existing issuable with scoped labels' do
  include_context 'exclusive labels creation' do
    let(:label1) { create_label('key::label1') }
    let(:label2) { create_label('key::label2') }
    let(:label3) { create_label('key::label3') }

    context 'scoped labels are avaialble' do
      before do
        stub_licensed_features(scoped_labels: true, epics: true)
      end

      it 'adds only last selected exclusive scoped label' do
        create(:label_link, label: label1, target: issuable)
        create(:label_link, label: label2, target: issuable)

        issuable.reload

        described_class.new(
          parent, user, label_ids: [label1.id, label3.id]
        ).execute(issuable)

        expect(issuable.reload.labels).to match_array([label3])
      end

      it 'preserves multiple exclusive scoped labels when only removing labels' do
        create(:label_link, label: label1, target: issuable)
        create(:label_link, label: label2, target: issuable)
        create(:label_link, label: label3, target: issuable)

        issuable.reload

        described_class.new(
          parent, user, label_ids: [label2.id, label3.id]
        ).execute(issuable)

        expect(issuable.reload.labels).to match_array([label2, label3])
      end
    end

    context 'scoped labels are not available' do
      before do
        stub_licensed_features(scoped_labels: false, epics: true)
      end

      it 'adds all scoped labels' do
        create(:label_link, label: label1, target: issuable)
        create(:label_link, label: label2, target: issuable)

        issuable.reload

        described_class.new(
          parent, user, label_ids: [label1.id, label2.id, label3.id]
        ).execute(issuable)

        expect(issuable.reload.labels).to match_array([label1, label2, label3])
      end
    end
  end
end
