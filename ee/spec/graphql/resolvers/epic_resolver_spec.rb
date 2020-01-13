# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::EpicResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user2) { create(:user) }

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

      context 'within timeframe' do
        let!(:epic1) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-20") }
        let!(:epic2) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-21") }

        context 'when start_date and end_date are present' do
          it 'returns epics within timeframe' do
            epics = resolve_epics(start_date: '2019-08-13', end_date: '2019-08-21')

            expect(epics).to match_array([epic1, epic2])
          end
        end

        context 'when only start_date is present' do
          it 'returns epics within timeframe' do
            expect { resolve_epics(start_date: '2019-08-13') }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
          end
        end

        context 'when only end_date is present' do
          it 'returns epics within timeframe' do
            expect { resolve_epics(end_date: '2019-08-13') }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
          end
        end
      end

      context 'with state' do
        let!(:epic1) { create(:epic, group: group, state: :opened, start_date: "2019-08-13", end_date: "2019-08-20") }
        let!(:epic2) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-21") }

        it 'lists epics with opened state' do
          epics = resolve_epics(state: 'opened')

          expect(epics).to match_array([epic1])
        end

        it 'lists epics with closed state' do
          epics = resolve_epics(state: 'closed')

          expect(epics).to match_array([epic2])
        end
      end

      context 'with search' do
        let!(:epic1) { create(:epic, group: group, title: 'first created', description: 'description') }
        let!(:epic2) { create(:epic, group: group, title: 'second created', description: 'text 1') }
        let!(:epic3) { create(:epic, group: group, title: 'third', description: 'text 2') }

        it 'filters epics by title' do
          epics = resolve_epics(search: 'created')

          expect(epics).to match_array([epic1, epic2])
        end

        it 'filters epics by description' do
          epics = resolve_epics(search: 'text')

          expect(epics).to match_array([epic2, epic3])
        end
      end

      context 'with author_username' do
        it 'filters epics by author' do
          user = create(:user)
          epic = create(:epic, group: group, author: user )
          create(:epic, group: group)

          epics = resolve_epics(author_username: user.username)

          expect(epics).to match_array([epic])
        end
      end

      context 'with label_name' do
        it 'filters epics by labels' do
          label_1 = create(:group_label, group: group)
          label_2 = create(:group_label, group: group)
          epic_1 = create(:labeled_epic, group: group, labels: [label_1, label_2])
          create(:labeled_epic, group: group, labels: [label_1])
          create(:labeled_epic, group: group)

          epics = resolve_epics(label_name: [label_1.title, label_2.title])

          expect(epics).to match_array([epic_1])
        end
      end

      context 'with sort' do
        let!(:epic1) { create(:epic, group: group, title: 'first created', description: 'description', start_date: 10.days.ago, end_date: 10.days.from_now) }
        let!(:epic2) { create(:epic, group: group, title: 'second created', description: 'text 1', start_date: 20.days.ago, end_date: 20.days.from_now) }
        let!(:epic3) { create(:epic, group: group, title: 'third', description: 'text 2', start_date: 30.days.ago, end_date: 30.days.from_now) }

        it 'orders epics by start date in descending order' do
          epics = resolve_epics(sort: 'start_date_desc')

          expect(epics).to eq([epic1, epic2, epic3])
        end

        it 'orders epics by start date in ascending order' do
          epics = resolve_epics(sort: 'start_date_asc')

          expect(epics).to eq([epic3, epic2, epic1])
        end

        it 'orders epics by end date in descending order' do
          epics = resolve_epics(sort: 'end_date_desc')

          expect(epics).to eq([epic3, epic2, epic1])
        end

        it 'orders epics by end date in ascending order' do
          epics = resolve_epics(sort: 'end_date_asc')

          expect(epics).to eq([epic1, epic2, epic3])
        end
      end

      context 'with subgroups' do
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
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
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
