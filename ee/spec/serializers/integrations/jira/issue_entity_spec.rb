# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Jira::IssueEntity do
  let(:project) { build(:project) }
  let(:jira_issue) do
    double(
      summary: 'summary',
      created: '2020-06-25T15:39:30.000+0000',
      updated: '2020-06-26T15:38:32.000+0000',
      resolutiondate: '2020-06-27T13:23:51.000+0000',
      labels: ['backend'],
      reporter: double('displayName' => 'reporter'),
      assignee: double('displayName' => 'assignee'),
      project: double(key: 'GL'),
      key: 'GL-5',
      client: double(options: { site: 'http://jira.com/' })
    )
  end

  subject { described_class.new(jira_issue, project: project).as_json }

  it 'returns the Jira issues attributes' do
    expect(subject).to include(
      project_id: project.id,
      title: 'summary',
      created_at: '2020-06-25T15:39:30.000+0000',
      updated_at: '2020-06-26T15:38:32.000+0000',
      closed_at: '2020-06-27T13:23:51.000+0000',
      labels: [
        {
          name: 'backend',
          color: '#b43fdd',
          text_color: '#FFFFFF'
        }
      ],
      author: { name: 'reporter' },
      assignees: [
        { name: 'assignee' }
      ],
      web_url: 'http://jira.com/projects/GL/issues/GL-5',
      references: { relative: 'GL-5' },
      external_tracker: 'jira'
    )
  end

  context 'without assignee' do
    before do
      allow(jira_issue).to receive(:assignee).and_return(nil)
    end

    it 'returns an empty array' do
      expect(subject).to include(assignees: [])
    end
  end

  context 'without labels' do
    before do
      allow(jira_issue).to receive(:labels).and_return([])
    end

    it 'returns an empty array' do
      expect(subject).to include(labels: [])
    end
  end
end
