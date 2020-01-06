# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StagePresenter < Gitlab::View::Presenter::Delegated
      DEFAULT_STAGE_ATTRIBUTES = {
        issue: {
          title: -> { s_('CycleAnalyticsStage|Issue') },
          description: -> { _('Time before an issue gets scheduled') }
        }.freeze,
        plan: {
          title: -> { s_('CycleAnalyticsStage|Plan') },
          description: -> { _('Time before an issue starts implementation') }
        }.freeze,
        code: {
          title: -> { s_('CycleAnalyticsStage|Code') },
          description: -> { _('Time until first merge request') }
        }.freeze,
        test: {
          title: -> { s_('CycleAnalyticsStage|Test') },
          description: -> { _('Total test time for all commits/merges') }
        }.freeze,
        review: {
          title: -> { s_('CycleAnalyticsStage|Review') },
          description: -> { _('Time between merge request creation and merge/close') }
        }.freeze,
        staging: {
          title: -> { s_('CycleAnalyticsStage|Staging') },
          description: -> { _('From merge request merge until deploy to production') }
        }.freeze,
        production: {
          title: -> { s_('CycleAnalyticsStage|Total') },
          description: -> { _('From issue creation until deploy to production') }
        }.freeze
      }.freeze

      def title
        extract_default_stage_attribute(:title) || name
      end

      def description
        extract_default_stage_attribute(:description) || ''
      end

      def legend
        ''
      end

      private

      def extract_default_stage_attribute(attribute)
        DEFAULT_STAGE_ATTRIBUTES.dig(name.to_sym, attribute.to_sym)&.call
      end
    end
  end
end
