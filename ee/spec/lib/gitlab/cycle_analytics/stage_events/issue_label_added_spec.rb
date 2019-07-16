require 'rails_helper'

describe Gitlab::CycleAnalytics::StageEvents::IssueLabelAdded do
  it 'takes always the first event' do
    project = create(:project)
    issue = create(:issue, :opened, project: project)
    label = create(:label, project: project)

    Issues::UpdateService.new(project, project.creator, label_ids: [label.id]).execute(issue)
    Issues::UpdateService.new(project, project.creator, label_ids: []).execute(issue)
    Issues::UpdateService.new(project, project.creator, label_ids: [label.id]).execute(issue)

    event = described_class.new(label: label)

    query = event.apply_query_customization(Issue.arel_table)

    expect(ActiveRecord::Base.connection.execute(query.to_sql).to_a.size).to eq 1
  end
end
