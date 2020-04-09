# frozen_string_literal: true

module Packages
  module Go
    class VersionFinder
      include ::API::Helpers::Packages::Go::ModuleHelpers

      attr_reader :mod

      def initialize(mod)
        @mod = mod
      end

      def execute
        @mod.project.repository.tags
          .filter { |tag| semver? tag }
          .map    { |tag| find_ref tag }
          .filter { |ver| ver.valid? }
      end

      def find(target)
        case target
        when String
          unless pseudo_version? target
            return mod.versions.filter { |v| v.name == target }.first
          end

          begin
            find_pseudo_version target
          rescue ArgumentError
            nil
          end

        when Gitlab::Git::Ref
          find_ref target

        when ::Commit, Gitlab::Git::Commit
          find_commit target

        else
          raise ArgumentError.new 'not a valid target'
        end
      end

      private

      def find_ref(ref)
        commit = ref.dereferenced_target
        Packages::GoModuleVersion.new(@mod, :ref, commit, ref: ref, semver: parse_semver(ref.name))
      end

      def find_commit(commit)
        Packages::GoModuleVersion.new(@mod, :commit, commit)
      end

      def find_pseudo_version(str)
        semver = parse_semver(str)
        raise ArgumentError.new 'target is not a pseudo-version' unless semver && PSEUDO_VERSION_REGEX.match?(str)

        # valid pseudo-versions are
        #   vX.0.0-yyyymmddhhmmss-sha1337beef0, when no earlier tagged commit exists for X
        #   vX.Y.Z-pre.0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z-pre
        #   vX.Y.(Z+1)-0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z

        # go discards the timestamp when resolving pseudo-versions, so we will do the same

        timestamp, sha = semver.prerelease.split('-').last 2
        timestamp = timestamp.split('.').last
        commit = @mod.project.repository.commit_by(oid: sha)

        # these errors are copied from proxy.golang.org's responses
        raise ArgumentError.new 'invalid pseudo-version: unknown commit' unless commit
        raise ArgumentError.new 'invalid pseudo-version: revision is shorter than canonical' unless sha.length == 12
        raise ArgumentError.new 'invalid pseudo-version: does not match version-control timestamp' unless commit.committed_date.strftime('%Y%m%d%H%M%S') == timestamp

        Packages::GoModuleVersion.new(@mod, :pseudo, commit, name: str, semver: semver)
      end
    end
  end
end
