# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_analytics' do
  it_behaves_like 'has nav sidebar'

  context 'top-level items' do
    context 'when feature flags are enabled' do
      it 'has `Analytics` link' do
        render

        expect(rendered).to have_content('Analytics')
        expect(rendered).to include(analytics_root_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#chart">/)
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

    context 'when user has access to instance statistics features' do
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
