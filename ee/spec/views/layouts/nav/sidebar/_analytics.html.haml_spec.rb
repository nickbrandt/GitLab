# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_analytics' do
  include AnalyticsHelpers

  it_behaves_like 'has nav sidebar'

  context 'top-level items' do
    context 'when feature flags are enabled' do
      it 'has `Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Analytics')
        expect(rendered).to include(analytics_root_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#chart">/)
      end

      it 'has `Productivity Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Productivity Analytics')
        expect(rendered).to include(analytics_productivity_analytics_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#comment">/)
      end

      it 'has `Cycle Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Cycle Analytics')
        expect(rendered).to include(analytics_cycle_analytics_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#repeat">/)
      end

      context 'and user has access to instance statistics features' do
        before do
          allow(view).to receive(:can?) { true }
        end

        it 'has `DevOps Score` link' do
          render

          expect(rendered).to have_content('DevOps Score')
          expect(rendered).to include(instance_statistics_dev_ops_score_index_path)
          expect(rendered).to match(/<use xlink:href=".+?icons-.+?#comment">/)
        end

        it 'has `Cohorts` link' do
          render

          expect(rendered).to have_content('Cohorts')
          expect(rendered).to include(instance_statistics_cohorts_path)
          expect(rendered).to match(/<use xlink:href=".+?icons-.+?#users">/)
        end
      end

      context 'and user does not have access to instance statistics features' do
        before do
          allow(view).to receive(:can?) { false }
        end

        it 'no instance statistics links are rendered' do
          render

          expect(rendered).not_to have_content('DevOps Score')
          expect(rendered).not_to have_content('Cohorts')
        end
      end
    end

    context 'when feature flags are disabled' do
      it 'no analytics links are rendered' do
        disable_all_analytics_feature_flags

        expect(rendered).not_to have_content('Productivity Analytics')
        expect(rendered).not_to have_content('Cycle Analytics')
      end

      context 'and user has access to instance statistics features' do
        before do
          allow(view).to receive(:can?) { true }
        end

        it 'has `DevOps Score` link' do
          render

          expect(rendered).to have_content('DevOps Score')
          expect(rendered).to include(instance_statistics_dev_ops_score_index_path)
          expect(rendered).to match(/<use xlink:href=".+?icons-.+?#comment">/)
        end

        it 'has `Cohorts` link' do
          render

          expect(rendered).to have_content('Cohorts')
          expect(rendered).to include(instance_statistics_cohorts_path)
          expect(rendered).to match(/<use xlink:href=".+?icons-.+?#users">/)
        end
      end

      context 'and user does not have access to instance statistics features' do
        before do
          allow(view).to receive(:can?) { false }
        end

        it 'no instance statistics links are rendered' do
          render

          expect(rendered).not_to have_content('DevOps Score')
          expect(rendered).not_to have_content('Cohorts')
        end
      end
    end
  end
end
