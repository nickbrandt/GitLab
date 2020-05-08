# frozen_string_literal: true

require 'spec_helper'

describe Admin::EmailsHelper do
  describe '#send_emails_from_admin_area_feature_available?' do
    subject { helper.send_emails_from_admin_area_feature_available? }

    context 'when `send_emails_from_admin_area` feature is enabled' do
      before do
        stub_licensed_features(send_emails_from_admin_area: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when `send_emails_from_admin_area` feature is disabled' do
      before do
        stub_licensed_features(send_emails_from_admin_area: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
