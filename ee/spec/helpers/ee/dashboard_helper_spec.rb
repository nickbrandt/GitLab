# frozen_string_literal: true

require 'spec_helper'

describe DashboardHelper, type: :helper do
  include AnalyticsHelpers

  let(:user) { build(:user) }

  describe '#dashboard_nav_links' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    describe 'analytics' do
      before do
        allow(helper).to receive(:can?) { true }
      end

      context 'when at least one analytics feature is enabled' do
        before do
          enable_only_one_analytics_feature_flag
        end

        it 'includes analytics' do
          expect(helper.dashboard_nav_links).to include(:analytics)
        end
      end

      context 'when all analytics features are disabled' do
        before do
          disable_all_analytics_feature_flags
        end

        context 'and the user has no access to instance statistics features' do
          before do
            allow(helper).to receive(:can?) { false }
          end

          it 'does not include analytics' do
            expect(helper.dashboard_nav_links).not_to include(:analytics)
          end
        end

        context 'and the user has access to instance statistics features' do
          it 'does include analytics' do
            expect(helper.dashboard_nav_links).to include(:analytics)
          end
        end
      end
    end

    describe 'operations, environments and security' do
      using RSpec::Parameterized::TableSyntax

      where(:ability, :feature_flag, :nav_link) do
        :read_operations_dashboard | nil                     | :operations
        :read_operations_dashboard | :environments_dashboard | :environments
        :read_security_dashboard   | :security_dashboard     | :security
      end

      with_them do
        describe 'when the feature is enabled' do
          before do
            stub_feature_flags(feature_flag => true) unless feature_flag.nil?
            allow(helper).to receive(:can?).and_return(false)
            allow(helper).to receive(:can?).with(user, ability).and_return(true)
          end

          it 'includes the nav link' do
            expect(helper.dashboard_nav_links).to include(nav_link)
          end
        end

        describe 'when the feature is disabled' do
          before do
            stub_feature_flags(feature_flag => false) unless feature_flag.nil?
            allow(helper).to receive(:can?).and_return(false)
          end

          it 'does not include the nav link' do
            expect(helper.dashboard_nav_links).not_to include(nav_link)
          end
        end
      end
    end
  end

  describe '.has_start_trial?' do
    using RSpec::Parameterized::TableSyntax

    where(:has_license, :current_user, :output) do
      false | :admin | true
      false | :user  | false
      true  | :admin | false
      true  | :user  | false
    end

    with_them do
      let(:user) { create(current_user) }
      let(:license) { has_license && create(:license) }
      subject { helper.has_start_trial? }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:current_license).and_return(license)
      end

      it { is_expected.to eq(output) }
    end
  end

  describe 'analytics_nav_url' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when any analytics features are enabled' do
      it 'returns the analytics root path' do
        expect(helper.analytics_nav_url).to match(analytics_root_path)
      end
    end

    context 'when analytics features are disabled' do
      before do
        disable_all_analytics_feature_flags
      end

      context 'and user has access to instance statistics features' do
        before do
          allow(helper).to receive(:can?) { true }
        end

        it 'returns the instance statistics root path' do
          expect(helper.analytics_nav_url).to match(instance_statistics_root_path)
        end
      end

      context 'and user does not have access to instance statistics features' do
        before do
          allow(helper).to receive(:can?) { false }
        end

        it 'returns the not found path' do
          expect(helper.analytics_nav_url).to match('errors/not_found')
        end
      end
    end
  end
end
