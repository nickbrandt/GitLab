# frozen_string_literal: true

require 'spec_helper'

describe ApprovalRules::ParamsFilteringService do
  let(:service) { described_class.new(merge_request, user, params) }
  let(:project_member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:accessible_group) { create(:group, :private) }
  let(:inaccessible_group) { create(:group, :private) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#execute' do
    before do
      project.add_maintainer(user)
      project.add_reporter(project_member)

      accessible_group.add_developer(user)

      allow(Ability).to receive(:allowed?).and_call_original

      allow(Ability)
        .to receive(:allowed?)
        .with(user, :update_approvers, merge_request)
        .and_return(can_update_approvers?)
    end

    shared_examples_for(:assigning_users_and_groups) do
      context 'user can update approvers' do
        let(:can_update_approvers?) { true }

        it 'only assigns eligible users and groups' do
          params = service.execute

          rule1 = params[:approval_rules_attributes].first

          expect(rule1[:user_ids]).to contain_exactly(project_member.id)

          rule2 = params[:approval_rules_attributes].last
          expected_group_ids = expected_groups.map(&:id)

          expect(rule2[:user_ids]).to be_empty
          expect(rule2[:group_ids]).to contain_exactly(*expected_group_ids)
        end
      end

      context 'user cannot update approvers' do
        let(:can_update_approvers?) { false }

        it 'deletes the approval_rules_attributes from params' do
          expect(service.execute).not_to have_key(:approval_rules_attributes)
        end
      end
    end

    context 'create' do
      let(:merge_request) { build(:merge_request, target_project: project, source_project: project) }
      let(:params) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1',
          approval_rules_attributes: approval_rules_attributes
        }
      end

      it_behaves_like :assigning_users_and_groups do
        let(:approval_rules_attributes) do
          [
            { name: 'foo', user_ids: [project_member.id, outsider.id] },
            { name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id] }
          ]
        end
        let(:expected_groups) { [accessible_group] }
      end

      context 'any approver rule' do
        let(:can_update_approvers?) { true }
        let(:approval_rules_attributes) do
          [
            { user_ids: [], group_ids: [] }
          ]
        end

        it 'sets rule type for the rules attributes' do
          params = service.execute
          rule = params[:approval_rules_attributes].first

          expect(rule[:rule_type]).to eq(:any_approver)
          expect(rule[:name]).to eq('All Members')
        end
      end
    end

    context 'update' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project)}
      let(:existing_private_group) { create(:group, :private) }
      let!(:rule1) { create(:approval_merge_request_rule, merge_request: merge_request, users: [create(:user)]) }
      let!(:rule2) { create(:approval_merge_request_rule, merge_request: merge_request, groups: [existing_private_group]) }

      it_behaves_like :assigning_users_and_groups do
        let(:params) do
          {
            approval_rules_attributes: [
              { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] },
              { id: rule2.id, name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id] }
            ]
          }
        end
        let(:expected_groups) { [accessible_group, existing_private_group] }
      end

      context 'with remove_hidden_groups being true' do
        it_behaves_like :assigning_users_and_groups do
          let(:params) do
            {
              approval_rules_attributes: [
                { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] },
                { id: rule2.id, name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id], remove_hidden_groups: true }
              ]
            }
          end
          let(:expected_groups) { [accessible_group] }
        end
      end
    end
  end
end
