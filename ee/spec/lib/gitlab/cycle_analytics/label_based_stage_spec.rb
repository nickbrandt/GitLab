# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CycleAnalytics::LabelBasedStage do
  def toggle_label_for_issue(issue, label, from, duration)
    project = issue.project

    Timecop.travel from do
      Issues::UpdateService.new(project, project.creator, label_ids: [label.id]).execute(issue)
    end

    Timecop.travel from + duration do
      Issues::UpdateService.new(project, project.creator, label_ids: []).execute(issue)
    end
  end

  let(:project) { create(:project) }
  let(:label) { create(:label, title: 'workflow::stage1', project: project) }
  let(:issue1) { create(:issue, project: project) }
  let(:issue2) { create(:issue, project: project) }
  let(:issue3) { create(:issue, project: project) }
  let(:from) { 10.weeks.ago }

  before do
    toggle_label_for_issue(issue1, label, from, 1.day)
    toggle_label_for_issue(issue2, label, from, 2.days)
    toggle_label_for_issue(issue3, label, from, 3.days)
  end

  describe "#median_in_days" do
    it "calculates correct median" do
      stage = described_class.new(label: label)

      expect(stage.median_in_days).to eq(2)
    end

    it "handles merging custom base query" do
      stage = described_class.new(label: label)

      median = stage.median_in_days do |resource_label_event_table, query_so_far|
        query_so_far.where(resource_label_event_table[:issue_id].eq(issue1.id))
      end

      expect(median).to eq(1)
    end

    it "unfinished stage finish time should be calculated until the current timestamp" do
      issue = create(:issue, project: project)

      Timecop.travel from do
        Issues::UpdateService.new(project, project.creator, label_ids: [label.id]).execute(issue)
      end

      Timecop.travel from + 5.days do
        stage = described_class.new(label: label)

        median = stage.median_in_days do |resource_label_event_table, query_so_far|
          query_so_far.where(resource_label_event_table[:issue_id].eq(issue.id))
        end

        expect(median).to eq(5)
      end
    end

    it "returns nil when median cannot be caluclated" do
      stage = described_class.new(label: create(:label))

      expect(stage.median_in_days).to eq(nil)
    end
  end
end
