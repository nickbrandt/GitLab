# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Admin do
  include EmailSpec::Matchers
  include ExternalAuthorizationServiceHelpers
  include NotificationHelpers


  let(:notification) { described_class.new }

  describe '#new_instance_access_request', :deliver_mails_inline do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }
    let_it_be(:admins) { create_list(:admin, 12, :with_sign_ins) }

    subject { notification.new_instance_access_request(user) }

    before do
      reset_delivered_emails!
      stub_application_setting(require_admin_approval_after_user_signup: true)
    end

    it 'sends notification only to a maximum of ten most recently active instance admins' do
      ten_most_recently_active_instance_admins = User.admins.active.sort_by(&:current_sign_in_at).last(10)

      subject

      should_only_email(*ten_most_recently_active_instance_admins)
    end
  end

  describe '#user_admin_rejection', :deliver_mails_inline do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }

    before do
      reset_delivered_emails!
    end

    it 'sends the user a rejection email' do
      notification.user_admin_rejection(user.name, user.email)

      should_only_email(user)
    end
  end
end
