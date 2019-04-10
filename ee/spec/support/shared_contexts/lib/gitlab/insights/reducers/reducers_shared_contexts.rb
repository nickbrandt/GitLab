# frozen_string_literal: true

RSpec.shared_context 'Insights reducers context' do
  around do |example|
    Timecop.freeze(Time.utc(2019, 5, 5)) { example.run }
  end

  let(:project) { create(:project, :public) }
  let(:label_bug) { create(:label, project: project, name: 'Bug') }
  let(:label_manage) { create(:label, project: project, name: 'Manage') }
  let(:label_plan) { create(:label, project: project, name: 'Plan') }
  let!(:issuable0) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 1, 5), project: project) }
  let!(:issuable1) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 1, 5), labels: [label_bug], project: project) }
  let!(:issuable2) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_manage, label_plan], project: project) }
  let!(:issuable3) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 4, 5), labels: [label_bug, label_plan], project: project) }
end
