# frozen_string_literal: true

module Gitlab
  class GlRepository
    class Identifier
      IllegalIdentifier = Class.new(ArgumentError)

      def self.parse(gl_repository_str)
        segments = gl_repository_str&.split('-')

        # gl_repository can either have 2 or 3 segments:
        # "wiki-1" is the older 2-segment format, where container is implied.
        # "group-1-wiki" is the newer 3-segment format, including container information.
        #
        # TODO: convert all 2-segment format to 3-segment:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/219192
        case segments&.size
        when 2
          TwoPartIdentifier.new(gl_repository_str, *segments)
        when 3
          ThreePartIdentifier.new(gl_repository_str, *segments)
        else
          raise IllegalIdentifier, %Q(Invalid GL Repository "#{gl_repository_str}")
        end
      end

      class TwoPartIdentifier < Identifier
        def initialize(gl_repository_str, repo_type_name, container_id_str)
          @gl_repository_str = gl_repository_str
          @repo_type_name = repo_type_name
          @container_id_str = container_id_str
        end

        def container_class
          repo_type.container_class
        end
      end

      class ThreePartIdentifier < Identifier
        attr_reader :container_type

        def initialize(gl_repository_str, container_type, container_id_str, repo_type_name)
          @gl_repository_str = gl_repository_str
          @container_type = container_type
          @container_id_str = container_id_str
          @repo_type_name = repo_type_name
        end

        def container_class
          case container_type
          when 'project'
            Project
          when 'group'
            Group
          else
            raise_error
          end
        end
      end

      def container
        @container ||= container_class.find_by_id(container_id)
      end

      def repo_type
        @repo_type ||= (Gitlab::GlRepository.types[repo_type_name] || raise_error)
      end

      private

      attr_reader :gl_repository_str, :container_id_str, :repo_type_name

      def container_id
        Integer(container_id_str, 10, exception: false) || raise_error
      end

      def raise_error
        raise IllegalIdentifier, %Q(Invalid GL Repository "#{gl_repository_str}")
      end
    end
  end
end
