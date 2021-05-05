# frozen_string_literal: true

module API
  module Entities
    class PublicGroupDetails < BasicGroupDetails
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :full_name, :full_path
      expose :visible do |group, options|
        group.id.in?(options.fetch(:visible_groups_ids, []))
      end
    end
  end
end
