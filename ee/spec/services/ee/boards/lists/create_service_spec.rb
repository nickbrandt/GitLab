# frozen_string_literal: true

require 'spec_helper'

describe Boards::Lists::CreateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board) { create(:board, project: project) }
    let(:user) { create(:user) }

    context 'when assignee_id param is sent' do
      let(:other_user) { create(:user) }
      subject(:service) { described_class.new(project, user, 'assignee_id' => other_user.id) }

      before do
        project.add_developer(user)
        project.add_developer(other_user)

        stub_licensed_features(board_assignee_lists: true)
      end

      it 'creates a new assignee list' do
        list = service.execute(board)

        expect(list.list_type).to eq('assignee')
        expect(list).to be_valid
      end
    end

    context 'when milestone_id param is sent' do
      let(:user) { create(:user) }
      let(:milestone) { create(:milestone, project: project) }
      subject(:service) { described_class.new(project, user, 'milestone_id' => milestone.id) }

      before do
        project.add_developer(user)

        stub_licensed_features(board_milestone_lists: true)
      end

      it 'creates a milestone list when param is valid' do
        list = service.execute(board)

        expect(list.list_type).to eq('milestone')
        expect(list).to be_valid
      end
    end

    context 'wip limits' do
      describe '#create_list_attributes' do
        subject(:service) { described_class.new(project, user, max_issue_count: 42) }

        context 'license unavailable' do
          before do
            stub_licensed_features(wip_limits: false)
          end

          it 'contains a max_issue_count of 0' do
            expect(service.create_list_attributes(nil, nil, nil)).to include(max_issue_count: 0)
          end
        end

        context 'license available' do
          before do
            stub_licensed_features(wip_limits: true)
          end

          it 'contains the params provided max issue count' do
            expect(service.create_list_attributes(nil, nil, nil)).to include(max_issue_count: 42)
          end
        end
      end
    end
  end
end
