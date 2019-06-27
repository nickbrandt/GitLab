# frozen_string_literal: true

module Gitlab
  module Insights
    module Finders
      class IssuableFinder
        IssuableFinderError = Class.new(StandardError)
        InvalidIssuableTypeError = Class.new(IssuableFinderError)
        InvalidGroupByError = Class.new(IssuableFinderError)
        InvalidPeriodLimitError = Class.new(IssuableFinderError)
        InvalidEntityError = Class.new(IssuableFinderError)

        FINDERS = {
          issue: ::IssuesFinder,
          merge_request: ::MergeRequestsFinder
        }.with_indifferent_access.freeze
        PERIODS = {
          days: { default: 30 },
          weeks: { default: 12 },
          months: { default: 12 }
        }.with_indifferent_access.freeze

        def initialize(entity, current_user, opts)
          @entity = entity
          @current_user = current_user
          @opts = opts
        end

        # Returns an Active Record relation of issuables.
        def find
          relation = finder
            .new(current_user, finder_args)
            .execute
          relation = relation.preload(:labels) if opts.key?(:collection_labels) # rubocop:disable CodeReuse/ActiveRecord

          relation
        end

        def period_limit
          @period_limit ||=
            if opts.key?(:period_limit)
              begin
                Integer(opts[:period_limit])
              rescue ArgumentError
                raise InvalidPeriodLimitError, "Invalid `:period_limit` option: `#{opts[:period_limit]}`. Expected an integer!"
              end
            else
              PERIODS.dig(period, :default)
            end
        end

        private

        attr_reader :entity, :current_user, :opts

        def finder
          issuable_type = opts[:issuable_type]&.to_sym

          FINDERS[issuable_type] ||
            raise(InvalidIssuableTypeError, "Invalid `:issuable_type` option: `#{opts[:issuable_type]}`. Allowed values are #{FINDERS.keys}!")
        end

        def finder_args
          {
            include_subgroups: true,
            state: opts[:issuable_state] || 'opened',
            label_name: opts[:filter_labels],
            sort: 'created_asc',
            created_after: created_after_argument
          }.merge(entity_key => entity.id)
        end

        def entity_key
          case entity
          when ::Project
            :project_id
          when ::Namespace
            :group_id
          else
            raise InvalidEntityError, "Entity class `#{entity.class}` is not supported. Supported classes are Project and Namespace!"
          end
        end

        def created_after_argument
          return unless opts.key?(:group_by)

          Time.zone.now.advance(period => -period_limit)
        end

        def period
          @period ||=
            if opts.key?(:group_by)
              period = opts[:group_by].to_s.pluralize.to_sym

              unless PERIODS.key?(period)
                raise InvalidGroupByError, "Invalid `:group_by` option: `#{opts[:group_by]}`. Allowed values are #{PERIODS.keys}!"
              end

              period
            else
              :days
            end
        end
      end
    end
  end
end
