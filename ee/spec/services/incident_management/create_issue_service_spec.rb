# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::CreateIssueService do
  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, nil, alert_payload) }
  let(:alert_title) { 'TITLE' }
  let(:alert_payload) do
    build_alert_payload(annotations: { title: alert_title })
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
        expect(issue.description).to include('Summary')
        expect(issue.description).to include(alert_title)
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

          expect(issue.description).to include('Summary')
          expect(issue.description).to include(alert_title)
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

    context 'with an invalid alert payload' do
      let(:alert_payload) { build_alert_payload(annotations: {}) }

      it 'does not create an issue' do
        expect(service)
          .to receive(:log_error)
          .with(error_message('invalid alert'))

        expect(subject).to eq(status: :error, message: 'invalid alert')
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

  def build_alert_payload(annotations: {})
    { 'annotations' => annotations.stringify_keys }
  end

  def error_message(message)
    %{Cannot create incident issue for "#{project.full_name}": #{message}}
  end
end
