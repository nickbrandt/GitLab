# frozen_string_literal: true

module Resolvers
  module DesignManagement
    module Version
      # Resolver for DesignAtVersion objects given an implicit version context
      class DesignsAtVersionResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type Types::DesignManagement::DesignAtVersionType, null: true

        authorize :read_design

        # For use in single resolver context
        argument :id, GraphQL::ID_TYPE,
                 required: false,
                 as: :design_at_version_id,
                 description: 'The ID of the DesignAtVersion'
        argument :design_id, GraphQL::ID_TYPE,
                 required: false,
                 description: 'The ID of a specific design'
        argument :filename, GraphQL::STRING_TYPE,
                 required: false,
                 description: 'The filename of a specific design'

        # For use in default (collection) context
        argument :ids,
                 [GraphQL::ID_TYPE],
                 required: false,
                 description: 'Filters designs by their ID'
        argument :filenames,
                 [GraphQL::STRING_TYPE],
                 required: false,
                 description: 'Filters designs by their filename'

        def resolve(ids: nil, filenames: nil, design_id: nil, filename: nil, design_at_version_id: nil)
          validate_arguments(ids, filenames, design_id, filename, design_at_version_id)

          return specific_design_at_version(design_at_version_id) if design_at_version_id

          design_ids = array_argument(design_id, ids)
          filenames = array_argument(filename, filenames)

          find(design_ids, filenames).execute.map { |d| make(d) }
        end

        private

        def validate_arguments(ids, filenames, design_id, filename, design_at_version_id)
          if single?
            expect_one(filename: filename, id: design_at_version_id, design_id: design_id)
            forbid(ids: ids, filenames: filenames)
          else
            forbid(filename: filename, id: design_at_version_id, design_id: design_id)
          end
        end

        # Take a nullable scalar object and a nullable array and return an
        # array of their values that is nil if both arguments are nil
        def array_argument(one, many)
          return if one.nil? && many.nil?

          Array.wrap(one).concat(Array.wrap(many))
        end

        def expect_one(args)
          passed = defined(args)

          return if passed.size == 1

          raise Gitlab::Graphql::Errors::ArgumentError, "Exactly one of #{args.keys.join(', ')} expected, got #{passed}"
        end

        def forbid(args)
          passed = defined(args)

          return if passed.empty?

          raise Gitlab::Graphql::Errors::ArgumentError, "Unexpected arguments: #{passed}"
        end

        def defined(args)
          args.each.select { |(_, v)| v.present? }.map(&:first)
        end

        def specific_design_at_version(id)
          return [] unless id.present? && Ability.allowed?(current_user, :read_design, issue)

          [find_dav_by_id(id)].select do |dav|
            dav.design.issue_id == issue.id && dav.version.id == version.id && dav.design.visible_in?(version)
          end
        end

        def find(ids, filenames)
          ids = ids&.map { |id| parse_design_id(id).model_id }

          ::DesignManagement::DesignsFinder.new(issue, current_user,
                                                ids: ids,
                                                filenames: filenames,
                                                visible_at_version: version)
        end

        def current_user
          context[:current_user]
        end

        def find_dav_by_id(id)
          GitlabSchema.object_from_id(id, expected_type: ::DesignManagement::DesignAtVersion)
        end

        def parse_design_id(id)
          GitlabSchema.parse_gid(id, expected_type: ::DesignManagement::Design)
        end

        def issue
          version.issue
        end

        def version
          object
        end

        def make(design)
          ::DesignManagement::DesignAtVersion.new(design: design, version: version)
        end
      end
    end
  end
end
