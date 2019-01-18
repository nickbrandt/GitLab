# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::BaseService do
  include ProjectForksHelper

  let(:project_member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:accessible_group) { create(:group, :private) }
  let(:inaccessible_group) { create(:group, :private) }

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#filter_params' do
    context 'filter users and groups' do
      shared_examples_for(:assigning_users_and_groups) do
        before do
          project.add_maintainer(user)
          project.add_reporter(project_member)

          accessible_group.add_developer(user)

          allow(service).to receive(:execute_hooks)
        end

        it 'only assigns eligible users and groups' do
          merge_request = subject

          rule1 = merge_request.approval_rules.regular.first

          expect(rule1.users).to contain_exactly(*project_member)

          rule2 = merge_request.approval_rules.regular.last

          expect(rule2.users).to be_empty
          expect(rule2.groups).to contain_exactly(*accessible_group)
        end
      end

      context 'create' do
        it_behaves_like :assigning_users_and_groups do
          let(:service) { MergeRequests::CreateService.new(project, user, opts) }
          let(:opts) do
            {
              title: 'Awesome merge_request',
              description: 'please fix',
              source_branch: 'feature',
              target_branch: 'master',
              force_remove_source_branch: '1',
              approval_rules_attributes: [
                { name: 'foo', user_ids: [project_member.id, outsider.id] },
                { name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id] }
              ]
            }
          end
          subject { service.execute }
        end
      end

      context 'update' do
        let(:merge_request) { create(:merge_request, target_project: project, source_project: project)}

        it_behaves_like :assigning_users_and_groups do
          let(:service) { MergeRequests::UpdateService.new(project, user, opts) }
          let(:opts) do
            {
              approval_rules_attributes: [
                { name: 'foo', user_ids: [project_member.id, outsider.id] },
                { name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id] }
              ]
            }
          end
          subject { service.execute(merge_request) }
        end
      end
    end
  end
end
