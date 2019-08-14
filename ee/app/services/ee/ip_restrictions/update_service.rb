# frozen_string_literal: true
module EE
  module IpRestrictions
    class UpdateService
      include ::Gitlab::Utils::StrongMemoize
      # This class is responsible for updating the ip_restrictions of a specific group.
      # It takes in comma separated subnets as input, eg: '192.168.1.0/8,10.0.0.0/8'

      # For a group with existing ip_restriction records, this service:
      # marks the records that exist for the group right now, but are not in `comma_separated_ranges` for deletion.
      # builds new ip_restriction records that do not exist for the group right now, but exists in `comma_separated_ranges`

      def initialize(group, comma_separated_ranges)
        @group = group
        @comma_separated_ranges = comma_separated_ranges
      end

      def execute
        mark_deleted_ranges_for_destruction
        build_new_ip_restriction_records
      end

      private

      attr_reader :group, :comma_separated_ranges

      def mark_deleted_ranges_for_destruction
        return unless ranges_to_be_deleted.present?

        group.ip_restrictions.each do |ip_restriction|
          if ranges_to_be_deleted.include? ip_restriction.range
            ip_restriction.mark_for_destruction
          end
        end
      end

      def build_new_ip_restriction_records
        return unless ranges_to_be_created.present?

        ranges_to_be_created.each do |range|
          group.ip_restrictions.build(range: range)
        end
      end

      def ranges_to_be_deleted
        strong_memoize(:ranges_to_be_deleted) do
          existing_ranges - current_ranges
        end
      end

      def ranges_to_be_created
        strong_memoize(:ranges_to_be_created) do
          current_ranges - existing_ranges
        end
      end

      def existing_ranges
        group.ip_restrictions.map(&:range)
      end

      def current_ranges
        comma_separated_ranges.split(",").map(&:strip).uniq
      end
    end
  end
end
