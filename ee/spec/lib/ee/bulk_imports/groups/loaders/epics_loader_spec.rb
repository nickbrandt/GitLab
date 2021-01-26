# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::BulkImports::Groups::Loaders::EpicsLoader do
  describe '#load' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:bulk_import) { create(:bulk_import, user: user) }
    let(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
    let(:context) { BulkImports::Pipeline::Context.new(entity) }

    let(:data) do
      {
        'title' => 'epic1',
        'state' => 'opened',
        'confidential' => false,
        'iid' => 1,
        'author_id' => user.id,
        'group_id' => group.id
      }
    end

    before do
      stub_licensed_features(epics: true)
      group.add_owner(user)
    end

    it 'creates the epic' do
      expect { subject.load(context, data) }.to change(::Epic, :count).by(1)

      expect(group.epics.count).to eq(1)
    end
  end
end
