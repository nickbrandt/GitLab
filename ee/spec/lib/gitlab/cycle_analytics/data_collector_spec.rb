require 'rails_helper'

describe Gitlab::CycleAnalytics::DataCollector do
  around do |example|
    Timecop.freeze { example.run }
  end

  # casting to days since asserting seconds are not reliable
  def round_to_days(seconds)
    seconds.fdiv(1.day.to_i).round
  end

  shared_examples 'custom cycle analytics stage' do
    before do
      # takes 10 days
      resource1 = Timecop.travel(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      Timecop.travel(Time.new(2019, 3, 15)) do
        create_data_for_end_event(resource1, self)
      end

      # takes 5 days
      resource2 = Timecop.travel(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      Timecop.travel(Time.new(2019, 3, 10)) do
        create_data_for_end_event(resource2, self)
      end

      # takes 15 days
      resource3 = Timecop.travel(Time.new(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      Timecop.travel(Time.new(2019, 3, 20)) do
        create_data_for_end_event(resource3, self)
      end
    end

    it 'loads serialized records for a given stage' do
      user = create(:user)
      project.add_user(user, Gitlab::Access::DEVELOPER)

      data_collector = described_class.new(stage, from: Time.new(2019), to: Time.new(2020), current_user: user)
      items = data_collector.records_fetcher.serialized_records

      expect(items.size).to eq(3)
    end

    it 'loads data for the scatterplot chart' do
      data_collector = described_class.new(stage, from: Time.new(2019), to: Time.new(2020))

      items = data_collector.with_end_date_and_duration_in_seconds
      a, b, c = items.sort_by { |i| i['duration_in_seconds'] }

      expect(round_to_days(a['duration_in_seconds'])).to eq(5)
      expect(round_to_days(b['duration_in_seconds'])).to eq(10)
      expect(round_to_days(c['duration_in_seconds'])).to eq(15)
    end

    it 'calculates median' do
      data_collector = described_class.new(stage, from: Time.new(2019), to: Time.new(2020))

      expect(round_to_days(data_collector.median.seconds)).to eq(10)
    end
  end

  shared_examples 'stage pairs' do
    describe 'for Issue related events' do
      describe 'between issue creation time and closing time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_closed }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.close!
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue creation time and first mentioned in commit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_mentioned_in_commit }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_mentioned_in_commit_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue first mentioned in commit and first associated with milestone time' do
        let(:start_event_identifier) { :issue_first_mentioned_in_commit }
        let(:end_event_identifier) { :issue_first_associated_with_milestone }

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)
          issue.metrics.update!(first_mentioned_in_commit_at: Time.now)
          issue
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_associated_with_milestone_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue creation time and first added to board time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_added_to_board }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_added_to_board_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue creation time and last edit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_last_edited }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue creation time and label added time' do
        let(:label) { create(:label, project: project) }
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_label_added }

        before do
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          Issues::UpdateService.new(example_class.project,
                                    example_class.project.creator,
                                    label_ids: [example_class.label.id]).execute(resource)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between issue label added time and label removed time' do
        let(:label) { create(:label, project: project) }
        let(:start_event_identifier) { :issue_label_added }
        let(:end_event_identifier) { :issue_label_removed }

        before do
          stage.start_event_label = label
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)

          Issues::UpdateService.new(
            example_class.project,
            example_class.project.creator,
            label_ids: [example_class.label.id]
          ).execute(issue)

          issue
        end

        def create_data_for_end_event(resource, example_class)
          Issues::UpdateService.new(
            example_class.project,
            example_class.project.creator,
            label_ids: []
          ).execute(resource)
        end

        it_behaves_like 'custom cycle analytics stage'
      end
    end

    describe 'for MergeRequest related events' do
      describe 'between merge request creation time and merge time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_merged }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(merged_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between merge request creation time and close time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_closed }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(latest_closed_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between merge request creation time and last edit time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_last_edited }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between merge request label added time and label removed time' do
        let(:label) { create(:label, project: project) }
        let(:start_event_identifier) { :merge_request_label_added }
        let(:end_event_identifier) { :merge_request_label_removed }

        before do
          stage.start_event_label = label
          stage.end_event_label = label
        end

        def create_data_for_start_event(example_class)
          merge_request = create(:merge_request, source_project: example_class.project, allow_broken: true)

          MergeRequests::UpdateService.new(
            example_class.project,
            example_class.project.creator,
            label_ids: [label.id]
          ).execute(merge_request)
        end

        def create_data_for_end_event(resource, example_class)
          MergeRequests::UpdateService.new(
            example_class.project,
            example_class.project.creator,
            label_ids: []
          ).execute(resource)
        end

        it_behaves_like 'custom cycle analytics stage'
      end

      describe 'between merge request build started time and build finished time' do
        let(:start_event_identifier) { :merge_request_last_build_started }
        let(:end_event_identifier) { :merge_request_last_build_finished }

        def create_data_for_start_event(example_class)
          merge_request = create(:merge_request, source_project: example_class.project, allow_broken: true)
          merge_request.metrics.update!(latest_build_started_at: Time.now)

          merge_request
        end

        def create_data_for_end_event(merge_request, example_class)
          merge_request.metrics.update!(latest_build_finished_at: Time.now)
        end

        it_behaves_like 'custom cycle analytics stage'
      end
    end
  end

  describe 'for ProjectStage' do
    it_behaves_like 'stage pairs' do
      let(:project) { create(:project, :empty_repo) }
      let(:stage) do
        CycleAnalytics::ProjectStage.new(
          name: 'My Stage',
          project: project,
          start_event_identifier: start_event_identifier,
          end_event_identifier: end_event_identifier
        )
      end
    end

    it 'ignores items outside of the date range' do
      user = create(:user)
      project = create(:project, :empty_repo)
      project.add_user(user, Gitlab::Access::DEVELOPER)

      stage = CycleAnalytics::ProjectStage.new(
        name: 'My Stage',
        project: project,
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_closed
      )

      Timecop.travel(Time.new(2018, 1, 1)) do
        mr = create(:merge_request, source_project: project, allow_broken: true)
        mr.metrics.update!(latest_closed_at: Time.now)
      end

      data_collector = described_class.new(stage, from: Time.new(2019, 1, 1), current_user: user)
      items = data_collector.records_fetcher.serialized_records

      expect(items).to be_empty
    end
  end

  describe 'for GroupStage' do
    it_behaves_like 'stage pairs' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :empty_repo, group: group) }
      let(:stage) do
        CycleAnalytics::GroupStage.new(
          name: 'My Stage',
          group: group,
          start_event_identifier: start_event_identifier,
          end_event_identifier: end_event_identifier
        )
      end

      before do
        group.add_user(project.creator, GroupMember::MAINTAINER)
      end
    end

    it 'supports filtering project_ids within the group' do
      group = create(:group)
      project1 = create(:project, :empty_repo, group: group)
      project2 = create(:project, :empty_repo, group: group)

      stage = CycleAnalytics::GroupStage.new(
        name: 'My Stage',
        group: group,
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_closed
      )

      Timecop.travel(Time.new(2019, 6, 1)) do
        mr = create(:merge_request, source_project: project1, allow_broken: true)
        mr.metrics.update!(latest_closed_at: Time.now)

        mr = create(:merge_request, source_project: project2, allow_broken: true)
        mr.metrics.update!(latest_closed_at: Time.now)
      end

      data_collector = described_class.new(stage, from: Time.new(2019, 1, 1), project_ids: [project2.id])
      items = data_collector.with_end_date_and_duration_in_seconds

      expect(items.size).to eq(1)
      expect(items.first["id"]).to eq(project2.merge_requests.first.id)
    end
  end
end
