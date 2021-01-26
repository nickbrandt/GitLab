# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::BulkImports::Groups::Transformers::EpicAttributesTransformer do
  describe '#transform' do
    let(:user) { create(:user) }
    let(:group) { create(:group, name: 'My Source Group') }
    let(:entity) do
      instance_double(
        BulkImports::Entity,
        group: group,
        namespace_id: group.id
      )
    end

    let(:context) do
      instance_double(
        BulkImports::Pipeline::Context,
        current_user: user,
        entity: entity
      )
    end

    let(:data) do
      {
        'iid' => '7',
        'title' => 'Epic Title',
        'description' => 'Epic Description',
        'state' => 'opened',
        'parent' => {
          'iid' => parent_iid
        },
        'children' => {
          'nodes' => [
            {
              'iid' => child_iid
            }
          ]
        }
      }
    end

    context 'when parent and child iids are nil' do
      let(:parent_iid) { nil }
      let(:child_iid) { nil }

      it 'sets group_id, author_id from context' do
        transformed_data = subject.transform(context, data)

        expect(transformed_data['group_id']).to eq(group.id)
        expect(transformed_data['author_id']).to eq(user.id)
        expect(transformed_data['parent']).to be_nil
      end
    end

    context 'when parent and child iids are present' do
      let(:parent) { create(:epic, group: group) }
      let(:child) { create(:epic, group: group) }
      let(:parent_iid) { parent.iid }
      let(:child_iid) { child.iid }

      it 'sets parent and child epics' do
        transformed_data = subject.transform(context, data)

        expect(transformed_data['parent']).to eq(parent)
        expect(transformed_data['children']).to contain_exactly(child)
      end
    end
  end
end
