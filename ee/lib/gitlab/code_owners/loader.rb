# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Loader
      def initialize(project, ref, paths)
        @project, @ref, @paths = project, ref, Array(paths)
      end

      def entries
        return [] if empty_code_owners?

        @entries ||= load_entries
      end

      def members
        @members ||= entries.map(&:users).flatten.uniq
      end

      def empty_code_owners?
        code_owners_file.empty?
      end

      private

      def load_entries
        entries = @paths.map { |path| code_owners_file.entry_for_path(path) }.compact.uniq
        members = all_members_for_entries(entries)

        entries.each do |entry|
          entry.add_matching_users_from(members)
        end

        entries
      end

      def all_members_for_entries(entries)
        owner_lines = entries.map(&:owner_line)
        all_users = Gitlab::UserExtractor.new(owner_lines).users.with_emails

        @project.members_among(all_users)
      end

      def code_owners_file
        if RequestStore.active?
          RequestStore.fetch("project-#{@project.id}:code-owners:#{@ref}") do
            load_code_owners_file
          end
        else
          load_code_owners_file
        end
      end

      def load_code_owners_file
        code_owners_blob = @project.repository.code_owners_blob(ref: @ref)
        Gitlab::CodeOwners::File.new(code_owners_blob)
      end
    end
  end
end
