# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ReorderService do
  let_it_be(:user)    { create_default(:user) }
  let_it_be(:group)   { create(:group) }
  let_it_be(:project, reload: true) { create(:project, namespace: group) }

  shared_examples 'issues reorder service' do
    context 'when reordering issues' do
      it 'returns false with no params' do
        expect(service({}).execute(issue1)).to be_falsey
      end

      it 'returns false with both invalid params' do
        params = { move_after_id: nil, move_before_id: non_existing_record_id }

        expect(service(params).execute(issue1)).to be_falsey
      end

      it 'moves the issue to the end if placement == :end' do
        params = { placement: :end }
        max_position = project.issues.maximum(:relative_position)

        expect do
          expect(service(params).execute(issue1)).to be_truthy
        end.to change(issue1, :relative_position).to(be > max_position)
      end

      it 'rebalances if needed' do
        params = { placement: :end }
        issue3.update!(relative_position: RelativePositioning::MAX_POSITION)

        expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)

        expect(service(params).execute(issue1)).to be_truthy
        expect(issue1.relative_position).to eq(project.issues.maximum(:relative_position))
      end

      it 'schedules rebalancing if there is no space left' do
        params = { placement: :end }
        allow(issue1).to receive(:move_to_end) { raise RelativePositioning::NoSpaceLeft }

        expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)

        expect { expect(service(params).execute(issue1)).to be_truthy }
          .to change(issue1, :relative_position).to(RelativePositioning::MAX_POSITION)
      end

      it 'does not schedule rebalancing if there is no space left but the feature flag is off' do
        params = { placement: :end }
        allow(issue1).to receive(:move_to_end) { raise RelativePositioning::NoSpaceLeft }
        stub_feature_flags(rebalance_issues: false)

        expect(IssueRebalancingWorker).not_to receive(:perform_async)

        expect { service(params).execute(issue1) }
          .to change(issue1, :relative_position).to(RelativePositioning::MAX_POSITION)
      end

      it 'does not rebalance if the rebalance_issues feature flag is disabled' do
        params = { placement: :end }
        issue3.update!(relative_position: RelativePositioning::MAX_POSITION)
        stub_feature_flags(rebalance_issues: false)

        expect(IssueRebalancingWorker).not_to receive(:perform_async)

        expect(service(params).execute(issue1)).to be_truthy
        expect(issue1.relative_position).to eq(project.issues.maximum(:relative_position))
      end

      it 'rebalances if the rebalance_issues feature flag is enabled for this current project' do
        params = { placement: :end }
        issue3.update!(relative_position: RelativePositioning::MAX_POSITION)
        stub_feature_flags(rebalance_issues: project)

        expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)

        expect(service(params).execute(issue1)).to be_truthy
        expect(issue1.relative_position).to eq(project.issues.maximum(:relative_position))
      end

      it 'sorts issues' do
        params = { move_after_id: issue2.id, move_before_id: issue3.id }

        service(params).execute(issue1)

        expect(issue1.relative_position)
          .to be_between(issue2.relative_position, issue3.relative_position)
      end

      it 'sorts issues if only given one neighbour, on the left' do
        params = { move_before_id: issue3.id }

        service(params).execute(issue1)

        expect(issue1.relative_position).to be > issue3.relative_position
      end

      it 'sorts issues if only given one neighbour, on the right' do
        params = { move_after_id: issue1.id }

        service(params).execute(issue3)

        expect(issue3.relative_position).to be < issue1.relative_position
      end
    end
  end

  describe '#execute' do
    let_it_be(:issue1, reload: true) { create(:issue, project: project, relative_position: 10) }
    let_it_be(:issue2) { create(:issue, project: project, relative_position: 20) }
    let_it_be(:issue3, reload: true) { create(:issue, project: project, relative_position: 30) }

    context 'when ordering issues in a project' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'issues reorder service'
    end

    context 'when ordering issues in a group' do
      before do
        group.add_developer(user)
      end

      it_behaves_like 'issues reorder service'

      context 'when ordering in a group issue list' do
        let(:params) { { move_after_id: issue2.id, move_before_id: issue3.id, group_full_path: group.full_path } }

        subject { service(params) }

        it 'sends the board_group_id parameter' do
          match_params = { move_between_ids: [issue2.id, issue3.id], board_group_id: group.id }

          expect(Issues::UpdateService)
            .to receive(:new).with(project, user, match_params)
            .and_return(double(execute: build(:issue)))

          subject.execute(issue1)
        end

        it 'sorts issues' do
          project2 = create(:project, namespace: group)
          issue4   = create(:issue, project: project2)

          subject.execute(issue4)

          expect(issue4.relative_position)
            .to be_between(issue2.relative_position, issue3.relative_position)
        end
      end
    end
  end

  def service(params)
    described_class.new(project, user, params)
  end
end
