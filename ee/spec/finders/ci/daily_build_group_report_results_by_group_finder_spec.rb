# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultsByGroupFinder do
  describe '#execute' do
    let(:user) { create(:user) }

    let(:project) { create(:project, :private) }
    let!(:project_coverage) { create_daily_coverage('rspec', 95.0, '2020-03-10', project) }

    let(:group) { create(:group, :private) }
    let(:group_project) { create(:project, namespace: group) }
    let!(:group_project_coverage) { create_daily_coverage('rspec', 79.0, '2020-03-09', group_project) }

    let(:subgroup) { create(:group, :private, parent: group) }
    let(:subgroup_project) { create(:project, namespace: subgroup) }
    let!(:subgroup_project_coverage) { create_daily_coverage('rspec', 89.0, '2020-03-09', subgroup_project) }

    let(:ref_path) { 'refs/heads/master' }
    let(:limit) { nil }

    subject do
      described_class.new(
        current_user: user,
        group: group,
        ref_path: ref_path,
        start_date: '2020-03-09',
        end_date: '2020-03-10',
        limit: limit
      ).execute
    end

    context 'when current user is allowed to :read_group_build_report_results' do
      before do
        group.add_reporter(user)
      end

      it 'returns only coverages belonging to the passed group' do
        expect(subject).to include(group_project_coverage)
        expect(subject).not_to include(project_coverage)
        expect(subject).not_to include(subgroup_project_coverage)
      end

      context 'with a limit below 1000' do
        let(:limit) { 5 }

        it 'uses the provided limit' do
          expect(subject.limit_value).to eq(5)
        end
      end

      context 'with a limit above 1000' do
        let(:limit) { 1001 }

        it 'uses the max constant' do
          expect(subject.limit_value).to eq(Ci::DailyBuildGroupReportResultsByGroupFinder::GROUP_QUERY_RESULT_LIMIT)
        end
      end

      context 'without a limit' do
        it 'uses the max constant' do
          expect(subject.limit_value).to eq(Ci::DailyBuildGroupReportResultsByGroupFinder::GROUP_QUERY_RESULT_LIMIT)
        end
      end
    end

    context 'without permmissions' do
      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  private

  def create_daily_coverage(group_name, coverage, date, project)
    create(
      :ci_daily_build_group_report_result,
      project: project,
      ref_path: ref_path,
      group_name: group_name,
      data: { 'coverage' => coverage },
      date: date
    )
  end
end
