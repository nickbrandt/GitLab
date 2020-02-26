# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::IncidentEntity do
  let_it_be(:issue) do
    create(:issue, title: ':ok:', description: ':tada:')
  end

  let(:json) { subject.as_json }

  subject { described_class.new(issue) }

  it 'exposes JSON fields' do
    expect(json).to eq(
      id: issue.iid,
      state: issue.state,
      title: issue.title_html,
      description: issue.description_html,
      updated_at: issue.updated_at,
      created_at: issue.created_at,
      comments: []
    )
  end

  context 'with user notes' do
    let(:user_notes) do
      create_list(:note, 1, noteable: issue, project: issue.project)
    end

    subject { described_class.new(issue, user_notes: user_notes) }

    it 'exposes comments' do
      expect(json).to include(:comments)
      expect(json[:comments].size).to eq(1)
    end
  end
end
