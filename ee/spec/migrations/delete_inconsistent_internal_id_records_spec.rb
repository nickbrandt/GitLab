# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180723130817_delete_inconsistent_internal_id_records.rb')

describe DeleteInconsistentInternalIdRecords, :migration do
  context 'for epics (by group)' do
    let(:groups) { table(:namespaces) }
    let(:users) { table(:users) }
    let(:group1) { groups.create(name: 'Group 1', type: 'Group', path: 'group_1') }
    let(:group2) { groups.create(name: 'Group 2', type: 'Group', path: 'group_2') }
    let(:group3) { groups.create(name: 'Group 2', type: 'Group', path: 'group_3') }
    let!(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

    let(:internal_id_query) { ->(group) { InternalId.where(usage: InternalId.usages['epics'], namespace_id: group.id) } }

    before do
      # we use state enum in Epic but state field was added after this migration
      epics = table(:epics)

      epics.belongs_to(:group)
      epics.include(AtomicInternalId)
      epics.has_internal_id(:iid, scope: :group, init: ->(s) { s&.group&.epics&.maximum(:iid) })

      epics.create!(title: 'Epic 1', title_html: 'Epic 1', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 2', title_html: 'Epic 2', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 3', title_html: 'Epic 3', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 4', title_html: 'Epic 4', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 5', title_html: 'Epic 5', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 6', title_html: 'Epic 6', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 7', title_html: 'Epic 7', group_id: group3.id, author_id: user.id)
      epics.create!(title: 'Epic 8', title_html: 'Epic 8', group_id: group3.id, author_id: user.id)
      epics.create!(title: 'Epic 9', title_html: 'Epic 9', group_id: group3.id, author_id: user.id)

      internal_id_query.call(group1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(group3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent records" do
      expect { migrate! }.to change { internal_id_query.call(group1).size }.from(1).to(0)
    end

    it "retains consistent records" do
      expect { migrate! }.not_to change { internal_id_query.call(group2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(group3).size }
    end
  end
end
