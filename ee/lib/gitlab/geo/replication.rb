# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      USER_UPLOADS_OBJECT_TYPES = %i[attachment avatar file import_export namespace_file personal_file favicon].freeze
      FILE_NOT_FOUND_GEO_CODE = 'FILE_NOT_FOUND'.freeze

      def self.object_type_from_user_uploads?(object_type)
        USER_UPLOADS_OBJECT_TYPES.include?(object_type.to_sym)
      end
    end
  end
end
