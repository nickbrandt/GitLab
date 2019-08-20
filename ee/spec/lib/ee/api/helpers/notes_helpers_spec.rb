require 'spec_helper'

describe 'NotesHelpers' do
  describe '#find_noteable' do
    let!(:group) { create(:group, :public) }
    let!(:other_group) { create(:group, :public) }
    let!(:project) { create(:project, :public, namespace: group) }
    let!(:user) { create(:group_member, :owner, group: group, user: create(:user)).user }
    let!(:epic) { create(:epic, author: user, group: group) }
    let!(:parent_id) { group.id }
    let!(:noteable_type) { Epic }

    let(:klazz) do
      klazz = Class.new do
        def initialize(user, group)
          @user = user
          @group = group
        end

        def current_user
          @user
        end

        def user_group
          @group
        end
      end

      klazz.prepend(EE::API::Helpers::NotesHelpers)
    end

    let(:subject) { klazz.new(user, group) }

    before do
      stub_licensed_features(epics: true)
    end

    it 'returns the expected epic' do
      expect(subject.find_group_epic(epic.id)).to eq(epic)
    end

    it 'raises not found exception when epic does not belong to group' do
      expect { klazz.new(user, other_group).find_group_epic(epic.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
