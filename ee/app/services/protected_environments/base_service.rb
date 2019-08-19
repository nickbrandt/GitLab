# frozen_string_literal: true
module ProtectedEnvironments
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    protected

    def sanitized_params
      params.dup.tap do |sanitized_params|
        sanitized_params[:deploy_access_levels_attributes] =
          filter_valid_groups(sanitized_params[:deploy_access_levels_attributes])
      end
    end

    private

    def filter_valid_groups(attributes)
      return unless attributes

      attributes.select do |attribute|
        attribute[:group_id].nil? || invited_group_ids.include?(attribute[:group_id])
      end
    end

    def invited_group_ids
      strong_memoize(:invited_group_ids) do
        project.invited_groups.pluck_primary_key.to_set
      end
    end
  end
end
