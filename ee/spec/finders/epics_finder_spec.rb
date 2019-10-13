# frozen_string_literal: true

require 'spec_helper'

describe EpicsFinder do
  let(:user) { create(:user) }
  let(:search_user) { create(:user) }
  let(:group) { create(:group, :private) }
  let(:another_group) { create(:group) }
  let!(:epic1) { create(:epic, :opened, group: group, title: 'This is awesome epic', created_at: 1.week.ago) }
  let!(:epic2) { create(:epic, :opened, group: group, created_at: 4.days.ago, author: user, start_date: 2.days.ago, end_date: 3.days.from_now) }
  let!(:epic3) { create(:epic, :closed, group: group, description: 'not so awesome', start_date: 5.days.ago, end_date: 3.days.ago) }
  let!(:epic4) { create(:epic, :closed, group: another_group) }

  describe '#execute' do
    def epics(params = {})
      params[:group_id] ||= group.id

      described_class.new(search_user, params).execute
    end

    context 'when epics feature is disabled' do
      before do
        group.add_developer(search_user)
      end

      it 'raises an exception' do
        expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
      end
    end

    # Enabling the `request_store` for this to avoid counting queries that check
    # the license.
    context 'when epics feature is enabled', :request_store do
      before do
        stub_licensed_features(epics: true)
      end

      context 'without param' do
        it 'raises an error when group_id param is missing' do
          expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
        end
      end

      context 'when user can not read epics of a group' do
        it 'raises an error when group_id param is missing' do
          expect { epics }.to raise_error { ArgumentError }
        end
      end

      context 'with correct params' do
        before do
          group.add_developer(search_user)
        end

        it 'returns all epics that belong to the given group' do
          expect(epics).to contain_exactly(epic1, epic2, epic3)
        end

        it 'does not execute more than 8 SQL queries' do
          expect { epics.to_a }.not_to exceed_all_query_limit(8)
        end

        context 'sorting' do
          it 'sorts correctly when supported sorting param provided' do
            expect(epics(sort: :start_date_asc)).to eq([epic3, epic2, epic1])
          end

          it 'sorts by id when not supported sorting param provided' do
            expect(epics(sort: :not_supported_param)).to eq([epic3, epic2, epic1])
          end
        end

        context 'by created_at' do
          it 'returns all epics created before the given date' do
            expect(epics(created_before: 2.days.ago)).to contain_exactly(epic1, epic2)
          end

          it 'returns all epics created after the given date' do
            expect(epics(created_after: 2.days.ago)).to contain_exactly(epic3)
          end

          it 'returns all epics created within the given interval' do
            expect(epics(created_after: 5.days.ago, created_before: 1.day.ago)).to contain_exactly(epic2)
          end
        end

        context 'by search' do
          it 'returns all epics that match the search' do
            expect(epics(search: 'awesome')).to contain_exactly(epic1, epic3)
          end
        end

        context 'by author' do
          it 'returns all epics authored by the given user' do
            expect(epics(author_id: user.id)).to contain_exactly(epic2)
          end
        end

        context 'by label' do
          let(:label) { create(:label) }
          let!(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }

          it 'returns all epics with given label' do
            expect(epics(label_name: label.title)).to contain_exactly(labeled_epic)
          end
        end

        context 'by state' do
          it 'returns all epics with given state' do
            expect(epics(state: :closed)).to contain_exactly(epic3)
          end
        end

        context 'when subgroups are supported' do
          let(:subgroup) { create(:group, :private, parent: group) }
          let(:subgroup2) { create(:group, :private, parent: subgroup) }
          let!(:subgroup_epic) { create(:epic, group: subgroup) }
          let!(:subgroup2_epic) { create(:epic, group: subgroup2) }

          it 'returns all epics that belong to the given group and its subgroups' do
            expect(epics).to contain_exactly(epic1, epic2, epic3, subgroup_epic, subgroup2_epic)
          end

          describe 'hierarchy params' do
            let(:finder_params) { {} }

            subject { epics(finder_params.merge(group_id: subgroup.id)) }

            it 'excludes ancestor groups and includes descendant groups by default' do
              is_expected.to contain_exactly(subgroup_epic, subgroup2_epic)
            end

            context 'when include_descendant_groups is false' do
              context 'and include_ancestor_groups is false' do
                let(:finder_params) { { include_descendant_groups: false, include_ancestor_groups: false } }

                it { is_expected.to contain_exactly(subgroup_epic) }
              end

              context 'and include_ancestor_groups is true' do
                let(:finder_params) { { include_descendant_groups: false, include_ancestor_groups: true } }

                it { is_expected.to contain_exactly(subgroup_epic, epic1, epic2, epic3) }
              end
            end

            context 'when include_descendant_groups is true' do
              context 'and include_ancestor_groups is false' do
                let(:finder_params) { { include_descendant_groups: true, include_ancestor_groups: false } }

                it { is_expected.to contain_exactly(subgroup_epic, subgroup2_epic) }
              end

              context 'and include_ancestor_groups is true' do
                let(:finder_params) { { include_descendant_groups: true, include_ancestor_groups: true } }

                it { is_expected.to contain_exactly(subgroup_epic, subgroup2_epic, epic1, epic2, epic3) }
              end
            end
          end

          it 'does not execute more than 14 SQL queries' do
            expect { epics.to_a }.not_to exceed_all_query_limit(14)
          end

          it 'does not execute more than 15 SQL queries when checking namespace plans' do
            allow(Gitlab::CurrentSettings)
              .to receive(:should_check_namespace_plan?)
              .and_return(true)

            create(:gitlab_subscription, :gold, namespace: group)

            expect { epics.to_a }.not_to exceed_all_query_limit(15)
          end
        end

        context 'by timeframe' do
          it 'returns epics which start in the timeframe' do
            params = {
              start_date: 2.days.ago.strftime('%Y-%m-%d'),
              end_date: 1.day.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic2)
          end

          it 'returns epics which end in the timeframe' do
            params = {
              start_date: 4.days.ago.strftime('%Y-%m-%d'),
              end_date: 3.days.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic3)
          end

          it 'returns epics which start before and end after the timeframe' do
            params = {
              start_date: 4.days.ago.strftime('%Y-%m-%d'),
              end_date: 4.days.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic3)
          end
        end

        context 'by parent' do
          before do
            epic2.update(parent: epic1)
            epic3.update(parent: epic2)
          end

          it 'returns direct children of the parent' do
            params = {
              parent_id: epic1.id
            }

            expect(epics(params)).to contain_exactly(epic2)
          end
        end

        context 'by iids' do
          let(:subgroup)  { create(:group, :private, parent: group) }
          let!(:subepic1) { create(:epic, group: subgroup, iid: epic1.iid) }

          it 'returns the specified epics' do
            params = { iids: [epic1.iid, epic2.iid] }

            expect(epics(params)).to contain_exactly(epic1, epic2)
          end

          it 'does not return epics from the sub-group with the same iid' do
            params = { iids: [epic1.iid] }

            expect(epics(params)).to contain_exactly(epic1)
          end
        end
      end
    end
  end

  describe '#row_count' do
    let(:label) { create(:label) }
    let(:label2) { create(:label) }
    let!(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }
    let!(:labeled_epic2) { create(:labeled_epic, group: group, labels: [label, label2]) }

    before do
      group.add_developer(search_user)
      stub_licensed_features(epics: true)
    end

    it 'returns number of rows when epics are grouped' do
      params = { group_id: group.id, label_name: [label.title, label2.title] }

      expect(described_class.new(search_user, params).row_count).to eq(1)
    end
  end

  describe '#count_by_state' do
    before do
      group.add_developer(search_user)
      stub_licensed_features(epics: true)
    end

    it 'returns correct counts' do
      results = described_class.new(search_user, group_id: group.id).count_by_state

      expect(results).to eq('opened' => 2, 'closed' => 1, 'all' => 3)
    end

    context 'when using group cte for search' do
      before do
        stub_feature_flags(use_subquery_for_group_issues_search: false)
      end

      it 'returns correct counts when search string is used' do
        results = described_class.new(
          search_user,
          group_id: group.id,
          search: 'awesome',
          attempt_group_search_optimizations: true
        ).count_by_state

        expect(results).to eq('opened' => 1, 'closed' => 1, 'all' => 2)
      end
    end
  end
end
