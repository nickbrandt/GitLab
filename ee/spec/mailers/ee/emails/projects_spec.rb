# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe EE::Emails::Projects do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  shared_examples 'no email' do
    it 'does not send mail' do
      expect(subject.message).to be_a_kind_of(ActionMailer::Base::NullMail)
    end
  end

  set(:user) { create(:user) }

  describe '#prometheus_alert_fired_email' do
    subject do
      Notify.prometheus_alert_fired_email(project.id, user.id, alert_params)
    end

    context 'with an alert' do
      let(:alert_params) do
        {
          'labels' => {
            'gitlab_alert_id' => alert.prometheus_metric_id.to_s
          }
        }
      end

      let(:environment) { alert.environment }

      let(:metrics_url) do
        metrics_project_environment_url(project, environment)
      end

      let!(:alert) { create(:prometheus_alert, project: project) }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'has expected subject' do
        aggregate_failures do
          is_expected.to have_subject(/Alert:/)
          is_expected.to have_subject(/#{environment.name}/)

          title = "#{alert.title} #{alert.computed_operator} #{alert.threshold}"
          is_expected.to have_subject(/#{title}/)
        end
      end

      it 'has expected content' do
        is_expected.to have_body_text('An alert has been triggered')
        is_expected.to have_body_text(project.full_path)
        is_expected.to have_body_text(environment.name)
        is_expected.to have_body_text(alert.full_query)
        is_expected.to have_body_text(metrics_url)
      end
    end

    context 'without an alert' do
      let(:alert_params) { {} }

      it_behaves_like 'no email'
    end

    context 'with an unknown alert' do
      let(:alert_params) do
        {
          'labels' => {
            'gitlab_alert_id' => 'unknown'
          }
        }
      end

      it_behaves_like 'no email'
    end
  end
end
