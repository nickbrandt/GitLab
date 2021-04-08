# frozen_string_literal: true

module API
  module Entities
    class PublicGroupDetails < BasicGroupDetails
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :full_name, :full_path
      expose :visible do |group, options|
        options[:visible_group_ids].include?(group.id)
      end
    end
  end
end
