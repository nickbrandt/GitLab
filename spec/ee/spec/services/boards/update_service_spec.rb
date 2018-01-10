require 'spec_helper'

describe Boards::UpdateService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let!(:board)  { create(:board, group: group, name: 'Backend') }

    it "updates board's name" do
      service = described_class.new(group, double, name: 'Engineering')

      service.execute(board)

      expect(board).to have_attributes(name: 'Engineering')
    end

    it 'returns true with valid params' do
      service = described_class.new(group, double, name: 'Engineering')

      expect(service.execute(board)).to eq true
    end

    it 'returns false with invalid params' do
      service = described_class.new(group, double, name: nil)

      expect(service.execute(board)).to eq false
    end

    context 'group board milestone' do
      let(:group) { create(:group) }
      let(:group_board) { create(:board, group: group, name: 'Backend Group') }
      let!(:milestone) { create(:milestone) }

      it 'is not updated if it is not within group milestones' do
        service = described_class.new(group, double, milestone_id: milestone.id)

        service.execute(group_board)

        expect(group_board.reload.milestone).to be_nil
      end

      it 'is updated if it is within group milestones' do
        milestone.update!(project: nil, group: group)
        service = described_class.new(group, double, milestone_id: milestone.id)

        service.execute(group_board)

        expect(group_board.reload.milestone).to eq(milestone)
      end
    end

    context 'project board milestone' do
      let(:project) { create(:project) }
      let!(:milestone) { create(:milestone) }

      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'is not updated if it is not within project milestones' do
        service = described_class.new(project, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to be_nil
      end

      it 'is updated if it is within project milestones' do
        milestone.update!(project: project)
        service = described_class.new(project, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to eq(milestone)
      end

      it 'is updated if it is within project group milestones' do
        project_group = create(:group)
        project.update(group: project_group)
        milestone.update!(project: nil, group: project_group)

        service = described_class.new(project_group, double, milestone_id: milestone.id)

        service.execute(board)

        expect(board.reload.milestone).to eq(milestone)
      end
    end
  end
end
