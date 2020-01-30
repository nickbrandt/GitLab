# frozen_string_literal: true

require 'spec_helper'

describe Event do
  describe '#visible_to_user?' do
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:author) { create(:author) }
    let_it_be(:admin) { create(:admin) }
    let(:epic) { create(:epic, group: group, author: author) }
    let(:note_on_epic) { create(:note, :on_epic, noteable: epic) }
    let(:event) { described_class.new(group: group, target: target, author: author) }

    before do
      stub_licensed_features(epics: true)
      group.add_developer(member)
      group.add_guest(guest)
    end

    shared_examples 'visible to group members only' do
      it 'is not visible to other users' do
        expect(event.visible_to_user?(non_member)).to eq false
        expect(event.visible_to_user?(member)).to eq true
        expect(event.visible_to_user?(guest)).to eq true
        expect(event.visible_to_user?(admin)).to eq true
      end
    end

    shared_examples 'visible to everybody' do
      it 'is visible to other users' do
        expect(event.visible_to_user?(non_member)).to eq true
        expect(event.visible_to_user?(member)).to eq true
        expect(event.visible_to_user?(guest)).to eq true
        expect(event.visible_to_user?(admin)).to eq true
      end
    end

    context 'epic event' do
      let(:target) { epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'on private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end

    context 'epic note event' do
      let(:target) { note_on_epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end
  end
end
