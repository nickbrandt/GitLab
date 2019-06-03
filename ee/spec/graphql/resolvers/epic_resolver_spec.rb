# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::EpicResolver do
  include GraphqlHelpers

  set(:current_user) { create(:user) }
  set(:user2) { create(:user) }

  context "with a group" do
    let(:group)   { create(:group) }
    let(:project) { create(:project, :public, group: group) }
    let(:epic1)   { create(:epic, group: group, state: :closed, created_at: 3.days.ago, updated_at: 2.days.ago) }
    let(:epic2)   { create(:epic, group: group, author: user2, title: 'foo', description: 'bar', created_at: 2.days.ago, updated_at: 3.days.ago) }

    before do
      group.add_developer(current_user)
      stub_licensed_features(epics: true)
    end

    describe '#resolve' do
      it 'returns nothing when feature disabled' do
        stub_licensed_features(epics: false)

        expect(resolve_epics).to be_empty
      end

      it 'finds all epics' do
        expect(resolve_epics).to contain_exactly(epic1, epic2)
      end

      context 'with iid' do
        it 'finds a specific epic with iid' do
          expect(resolve_epics(iid: epic1.iid)).to contain_exactly(epic1)
        end

        it 'does not inflate the complexity' do
          field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 100)

          expect(field.to_graphql.complexity.call({}, { iid: [epic1.iid] }, 5)).to eq 6
        end
      end

      context 'with iids' do
        it 'finds a specific epic with iids' do
          expect(resolve_epics(iids: epic1.iid)).to contain_exactly(epic1)
        end

        it 'finds multiple epics with iids' do
          expect(resolve_epics(iids: [epic1.iid, epic2.iid]))
              .to contain_exactly(epic1, epic2)
        end

        it 'increases the complexity based on child_complexity and number of iids' do
          field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: described_class, null: false, max_page_size: 100)

          expect(field.to_graphql.complexity.call({}, { iids: [epic1.iid] }, 5)).to eq 6
          expect(field.to_graphql.complexity.call({}, { iids: [epic1.iid, epic2.iid] }, 5)).to eq 11
        end
      end

      context 'with subgroups', :nested_groups do
        let(:sub_group) { create(:group, parent: group) }
        let(:iids)      { [epic1, epic2].map(&:iid) }
        let!(:epic3)    { create(:epic, group: sub_group, iid: epic1.iid) }
        let!(:epic4)    { create(:epic, group: sub_group, iid: epic2.iid) }

        before do
          sub_group.add_developer(current_user)
        end

        it 'finds only the epics within the group we are looking at' do
          expect(resolve_epics(iids: iids)).to contain_exactly(epic1, epic2)
        end

        it 'return all epics' do
          expect(resolve_epics).to contain_exactly(epic1, epic2, epic3, epic4)
        end
      end
    end
  end

  context "when passing a non existent, batch loaded group" do
    let(:group) do
      BatchLoader.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_epics(iids: ["don't", "break"])).to be_empty
    end
  end

  def resolve_epics(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: group, args: args, ctx: context)
  end
end
