require 'spec_helper'

describe Burndown do
  set(:user) { create(:user) }
  set(:non_member) { create(:user) }
  let(:start_date) { "2017-03-01" }
  let(:due_date) { "2017-03-03" }

  shared_examples 'burndown for milestone' do
    before do
      build_sample(milestone, issue_params)
    end

    around do |example|
      Timecop.travel(due_date) do
        example.run
      end
    end

    subject { described_class.new(milestone, user).to_json }

    it "generates an array with date, issue count and weight" do
      expect(subject).to eq([
        ["2017-03-01", 4, 8],
        ["2017-03-02", 5, 10],
        ["2017-03-03", 3, 6]
      ].to_json)
    end

    it "returns empty array if milestone start date is nil" do
      milestone.update(start_date: nil)

      expect(subject).to eq([].to_json)
    end

    it "returns empty array if milestone due date is nil" do
      milestone.update(due_date: nil)

      expect(subject).to eq([].to_json)
    end

    it "it counts until today if milestone due date > Date.today" do
      Timecop.travel(milestone.due_date - 1.day) do
        expect(JSON.parse(subject).last[0]).to eq(Time.now.strftime("%Y-%m-%d"))
      end
    end

    it "sets attribute accurate to true" do
      burndown = described_class.new(milestone, user)

      expect(burndown).to be_accurate
    end

    context "when all closed issues does not have closed events" do
      before do
        Event.where(target: milestone.issues, action: Event::CLOSED).destroy_all # rubocop: disable DestroyAll
      end

      it "considers closed_at as milestone start date" do
        expect(subject).to eq([
          ["2017-03-01", 4, 8],
          ["2017-03-02", 4, 8],
          ["2017-03-03", 4, 8]
        ].to_json)
      end

      it "sets attribute empty to true" do
        burndown = described_class.new(milestone, user)

        expect(burndown).to be_empty
      end
    end

    context "when one or more closed issues does not have a closed event" do
      before do
        Event.where(target: milestone.issues.closed.first, action: Event::CLOSED).destroy_all # rubocop: disable DestroyAll
      end

      it "sets attribute accurate to false" do
        burndown = described_class.new(milestone, user)

        expect(burndown).not_to be_accurate
      end
    end

    context 'when issues are created at the middle of the milestone' do
      let(:creation_date) { "2017-03-02" }

      it 'accounts for counts in issues created at the middle of the milestone' do
        project = try(:group_project) || try(:project)

        create(:issue, milestone: milestone, project: project, created_at: creation_date, weight: 2)
        create(:issue, milestone: milestone, project: project, created_at: creation_date, weight: 3)

        expect(subject).to eq([
          ['2017-03-01', 4, 8],
          ['2017-03-02', 7, 15],
          ['2017-03-03', 5, 11]
        ].to_json)
      end
    end

    context 'when issues belong to a public project' do
      it 'does not include confidential issues for users who are not project members' do
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

        expected_result = [
            ["2017-03-01", 3, 6],
            ["2017-03-02", 4, 8],
            ["2017-03-03", 2, 4]
        ].to_json

        expect(described_class.new(milestone, non_member).to_json).to eq(expected_result)
      end
    end
  end

  describe 'project milestone burndown' do
    it_behaves_like 'burndown for milestone' do
      let(:milestone) { create(:milestone, start_date: start_date, due_date: due_date) }
      let(:project) { milestone.project }
      let(:issue_params) do
        {
          milestone: milestone,
          weight: 2,
          project_id: project.id,
          author: user,
          created_at: milestone.start_date
        }
      end
      let(:scope) { project }
    end
  end

  describe 'group milestone burndown' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:group_project) { create(:project, group: group) }
    let(:nested_group_project) { create(:project, group: nested_group) }
    let(:group_milestone) { create(:milestone, project: nil, group: group, start_date: start_date, due_date: due_date) }
    let(:nested_group_milestone) { create(:milestone, group: nested_group, start_date: start_date, due_date: due_date) }

    context 'when nested group milestone', :nested_groups do
      before do
        group.add_developer(user)
      end

      it_behaves_like 'burndown for milestone' do
        let(:milestone) { nested_group_milestone }
        let(:project) { nested_group_project }
        let(:issue_params) do
          {
            milestone: milestone,
            weight: 2,
            project_id: nested_group_project.id,
            author: user,
            created_at: milestone.start_date
          }
        end
        let(:scope) { group }
      end
    end

    context 'when non-nested group milestone' do
      it_behaves_like 'burndown for milestone' do
        let(:milestone) { group_milestone }
        let(:project) { group_project }
        let(:issue_params) do
          {
            milestone: milestone,
            weight: 2,
            project_id: group_project.id,
            author: user,
            created_at: milestone.start_date
          }
        end
        let(:scope) { group }
      end
    end
  end

  # Creates, closes and reopens issues only for odd days numbers
  def build_sample(milestone, issue_params)
    project.add_master(user)

    milestone.start_date.upto(milestone.due_date) do |date|
      day = date.day
      next if day.even?

      count = day
      Timecop.travel(date) do
        # Create issues
        issues = create_list(:issue, count, issue_params)

        issues.each do |issue|
          # Turns out we need to make sure older events that are not "closed"
          # won't be caught by the query.
          Event.create!(author: user,
                        target: issue,
                        created_at: Date.yesterday,
                        action: Event::CREATED)
        end

        # Close issues
        closed = issues.slice(0..count / 2)
        closed.each { |issue| close_issue(issue) }

        # Reopen issues
        reopened_issues = closed.slice(0..count / 4)
        reopened_issues.each { |issue| reopen_issue(issue) }

        # This generates an issue with multiple closing events
        issue_closed_twice = reopened_issues.last
        close_issue(issue_closed_twice)
        reopen_issue(issue_closed_twice)

        # create one confidential issue
        create(:issue, :confidential, issue_params) if Date.today == milestone.start_date
      end
    end
  end

  def close_issue(issue)
    Issues::CloseService.new(issue.project, user, {}).execute(issue)
  end

  def reopen_issue(issue)
    Issues::ReopenService.new(issue.project, user, {}).execute(issue)
  end
end
