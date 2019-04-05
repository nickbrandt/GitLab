# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20190327085945_remove_cyclic_hierarchies_in_epics.rb')

describe RemoveCyclicHierarchiesInEpics, :migration, :postgresql do
  let(:epics) { table(:epics) }
  let(:group) { table(:namespaces).create(name: 'Group 1', type: 'Group', path: 'group_1') }
  let(:user) { table(:users).create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

  def create_epic_with_defaults!(attributes = {})
    @last_iid += 1

    epics.create!(
      attributes.reverse_merge(
        iid: @last_iid,
        group_id: group.id,
        author_id: user.id,
        title: "Epic",
        title_html: "Epic"
      )
    )
  end

  let!(:epic_self_loop) { create_epic_with_defaults! }
  let!(:epic_loop_1) { create_epic_with_defaults! }
  let!(:epic_loop_2) { create_epic_with_defaults! }

  let!(:epic_not_in_loop) { create_epic_with_defaults! }

  before(:all) do
    @last_iid = 0
  end

  before do
    epic_self_loop.update(parent_id: epic_self_loop.id)

    epic_loop_1_1 = create_epic_with_defaults!(parent_id: epic_loop_1.id)
    epic_loop_1.update(parent_id: epic_loop_1_1.id)

    epic_loop_2_1 = create_epic_with_defaults!(parent_id: epic_loop_2.id)
    epic_loop_2_2 = create_epic_with_defaults!(parent_id: epic_loop_2_1.id)
    epic_loop_2_3 = create_epic_with_defaults!(parent_id: epic_loop_2_2.id)
    epic_loop_2.update(parent_id: epic_loop_2_3.id)

    epic_parent = create_epic_with_defaults!
    epic_not_in_loop.update(parent_id: epic_parent.id)
  end

  it 'clears parent_id of epic in loop' do
    migrate!

    expect(epic_self_loop.reload.parent_id).to be_nil
    expect(epic_loop_1.reload.parent_id).to be_nil
    expect(epic_loop_2.reload.parent_id).to be_nil
  end

  it 'does not clear parent_id for other epics' do
    migrate!

    expect(epic_not_in_loop.reload.parent_id).not_to be_nil
  end
end
