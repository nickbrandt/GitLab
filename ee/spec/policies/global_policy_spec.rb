# frozen_string_literal: true

require 'spec_helper'

describe GlobalPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe 'reading operations dashboard' do
    context 'when licensed' do
      before do
        stub_licensed_features(operations_dashboard: true)
      end

      it { is_expected.to be_allowed(:read_operations_dashboard) }

      context 'and the user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.not_to be_allowed(:read_operations_dashboard) }
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(operations_dashboard: false)
      end

      it { is_expected.not_to be_allowed(:read_operations_dashboard) }
    end
  end

  it { is_expected.to be_disallowed(:read_licenses) }
  it { is_expected.to be_disallowed(:destroy_licenses) }

  it { expect(described_class.new(create(:admin), [user])).to be_allowed(:read_licenses) }
  it { expect(described_class.new(create(:admin), [user])).to be_allowed(:destroy_licenses) }

  shared_examples 'analytics policy' do |action|
    context 'anonymous user' do
      let(:current_user) { nil }

      it 'is not allowed' do
        is_expected.not_to be_allowed(action)
      end
    end

    context 'authenticated user' do
      it 'is allowed' do
        is_expected.to be_allowed(action)
      end
    end
  end

  describe 'view_code_analytics' do
    include_examples 'analytics policy', :view_code_analytics
  end

  describe 'view_productivity_analytics' do
    include_examples 'analytics policy', :view_productivity_analytics
  end

  describe 'read_security_dashboard' do
    context 'when the instance has an Ultimate license' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'and the user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.not_to be_allowed(:read_security_dashboard) }
      end

      context 'and the user is logged in' do
        it { is_expected.to be_allowed(:read_security_dashboard) }
      end
    end

    context 'when the instance does not have an Ultimate license' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it { is_expected.not_to be_allowed(:read_security_dashboard) }
    end
  end

  describe 'update_max_pages_size' do
    context 'when feature is enabled' do
      before do
        stub_licensed_features(pages_size_limit: true)
      end

      it { is_expected.to be_disallowed(:update_max_pages_size) }
      it { expect(described_class.new(create(:admin), [user])).to be_allowed(:update_max_pages_size) }
    end

    it { expect(described_class.new(create(:admin), [user])).to be_disallowed(:update_max_pages_size) }
  end
end
