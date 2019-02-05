# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Entry
      Data = Struct.new(:pattern, :owner_line)

      attr_reader :data
      protected :data

      delegate :pattern, :hash, :owner_line, to: :data

      def initialize(pattern, owner_line)
        @data = Data.new(pattern, owner_line)
      end

      def users
        raise "CodeOwners for #{owner_line} not loaded" unless defined?(@users)

        @users.to_a
      end

      def add_matching_users_from(new_users)
        @users ||= Set.new

        matching_users = new_users.select { |u| matching_user?(u) }
        @users.merge(matching_users)
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        data == other.data
      end
      alias_method :eql?, :==

      private

      def extractor
        @extractor ||= Gitlab::UserExtractor.new(owner_line)
      end

      def emails
        @emails ||= extractor.emails.map(&:downcase)
      end

      def usernames
        @usernames ||= extractor.usernames.map(&:downcase)
      end

      def matching_user?(user)
        usernames.include?(user.username.downcase) || matching_emails?(user)
      end

      def matching_emails?(user)
        raise "Emails not loaded for #{user}" unless user.emails.loaded?

        emails.any? { |email| user.any_email?(email) }
      end
    end
  end
end
