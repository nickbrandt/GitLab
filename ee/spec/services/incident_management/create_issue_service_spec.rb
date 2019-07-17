# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::CreateIssueService do
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, nil, alert_payload) }
  let(:alert_starts_at) { Time.now }
  let(:alert_title) { 'TITLE' }
  let(:alert_annotations) { { title: alert_title } }

  let(:alert_payload) do
    build_alert_payload(
      annotations: alert_annotations,
      starts_at: alert_starts_at
    )
  end

  let(:alert_presenter) do
    Gitlab::Alerting::Alert.new(project: project, payload: alert_payload).present
  end

  let!(:setting) do
    create(:project_incident_management_setting, project: project)
  end

  subject { service.execute }

  context 'when create_issue enabled' do
    let(:issue) { subject[:issue] }
    let(:summary_separator) { "---\n\n" }

    before do
      setting.update!(create_issue: true)
    end

    context 'without issue_template_content' do
      it 'creates an issue with alert summary only' do
        expect(subject).to include(status: :success)

        expect(issue.author).to eq(User.alert_bot)
        expect(issue.title).to eq(alert_title)
        expect(issue.description).to include(alert_presenter.issue_summary_markdown)
        expect(issue.description).not_to include(summary_separator)
      end
    end

    context 'with issue_template_content' do
      before do
        create_issue_template('bug', issue_template_content)
        setting.update!(issue_template_key: 'bug')
      end

      context 'plain content' do
        let(:issue_template_content) { 'some content' }

        it 'creates an issue appending issue template' do
          expect(subject).to include(status: :success)

          expect(issue.description).to include(alert_presenter.issue_summary_markdown)
          expect(issue.description).to include(summary_separator)
          expect(issue.description).to include(issue_template_content)
        end
      end

      context 'quick actions' do
        let(:user) { create(:user) }
        let(:plain_text) { 'some content' }

        let(:issue_template_content) do
          <<~CONTENT
            #{plain_text}
            /due tomorrow
            /assign @#{user.username}
          CONTENT
        end

        before do
          project.add_maintainer(user)
        end

        it 'creates an issue interpreting quick actions' do
          expect(subject).to include(status: :success)

          expect(issue.description).to include(plain_text)
          expect(issue.due_date).to be_present
          expect(issue.assignees).to eq([user])
        end
      end

      private

      def create_issue_template(name, content)
        project.repository.create_file(
          project.creator,
          ".gitlab/issue_templates/#{name}.md",
          content,
          message: 'message',
          branch_name: 'master'
        )
      end
    end

    context 'with gitlab alert' do
      let(:gitlab_alert) { create(:prometheus_alert, project: project) }

      before do
        alert_payload['labels'] = {
          'gitlab_alert_id' => gitlab_alert.prometheus_metric_id.to_s
        }
      end

      it 'creates an issue' do
        query_title = "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold}"

        expect(subject).to include(status: :success)

        expect(issue.author).to eq(User.alert_bot)
        expect(issue.title).to eq(alert_presenter.full_title)
        expect(issue.title).to include(gitlab_alert.environment.name)
        expect(issue.title).to include(query_title)
        expect(issue.title).to include('for 5 minutes')
        expect(issue.description).to include(alert_presenter.issue_summary_markdown)
        expect(issue.description).not_to include(summary_separator)
      end
    end

    describe 'with invalid alert payload' do
      shared_examples 'invalid alert' do
        it 'does not create an issue' do
          expect(service)
            .to receive(:log_error)
            .with(error_message('invalid alert'))

          expect(subject).to eq(status: :error, message: 'invalid alert')
        end
      end

      context 'without title' do
        let(:alert_annotations) { {} }

        it_behaves_like 'invalid alert'
      end

      context 'without startsAt' do
        let(:alert_starts_at) { nil }

        it_behaves_like 'invalid alert'
      end
    end
  end

  context 'when create_issue disabled' do
    before do
      setting.update!(create_issue: false)
    end

    it 'returns an error' do
      expect(service)
        .to receive(:log_error)
        .with(error_message('setting disabled'))

      expect(subject).to eq(status: :error, message: 'setting disabled')
    end
  end

  private

  def build_alert_payload(annotations: {}, starts_at: Time.now)
    {
      'annotations' => annotations.stringify_keys
    }.tap do |payload|
      payload['startsAt'] = starts_at.rfc3339 if starts_at
    end
  end

  def error_message(message)
    %{Cannot create incident issue for "#{project.full_name}": #{message}}
  end
end
