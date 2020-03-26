# frozen_string_literal: true

class Packages::GoModuleVersion
  SEMVER_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?/i.freeze
  SEMVER_TAG_REGEX = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?$/i.freeze
  PSEUDO_VERSION_REGEX = /^v\d+\.(0\.0-|\d+\.\d+-([^+]*\.)?0\.)\d{14}-[A-Za-z0-9]+(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$/i.freeze
  VERSION_SUFFIX_REGEX = /\/v([1-9]\d*)$/i.freeze

  attr_reader :mod, :type, :ref, :commit

  delegate :major, to: :@semver, allow_nil: true
  delegate :minor, to: :@semver, allow_nil: true
  delegate :patch, to: :@semver, allow_nil: true
  delegate :prerelease, to: :@semver, allow_nil: true
  delegate :build, to: :@semver, allow_nil: true

  def self.semver?(tag)
    return false if tag.dereferenced_target.nil?

    SEMVER_TAG_REGEX.match?(tag.name)
  end

  def self.pseudo_version?(str)
    SEMVER_TAG_REGEX.match?(str) && PSEUDO_VERSION_REGEX.match?(str)
  end

  def initialize(mod, target)
    @mod = mod

    case target
    when String
      m = SEMVER_TAG_REGEX.match(target)
      raise ArgumentError.new 'target is not a pseudo-version' unless m && PSEUDO_VERSION_REGEX.match?(target)

      # valid pseudo-versions are
      #   vX.0.0-yyyymmddhhmmss-sha1337beef0, when no earlier tagged commit exists for X
      #   vX.Y.Z-pre.0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z-pre
      #   vX.Y.(Z+1)-0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z

      # go discards the timestamp when resolving pseudo-versions, so we will do the same

      @type = :pseudo
      @name = target
      @semver = semver_match_to_hash m

      timestamp, sha = prerelease.split('-').last 2
      timestamp = timestamp.split('.').last
      @commit = mod.project.repository.commit_by(oid: sha)

      # these errors are copied from proxy.golang.org's responses
      raise ArgumentError.new 'invalid pseudo-version: unknown commit' unless @commit
      raise ArgumentError.new 'invalid pseudo-version: revision is shorter than canonical' unless sha.length == 12
      raise ArgumentError.new 'invalid pseudo-version: does not match version-control timestamp' unless @commit.committed_date.strftime('%Y%m%d%H%M%S') == timestamp

    when Gitlab::Git::Ref
      @type = :ref
      @ref = target
      @commit = target.dereferenced_target
      @semver = semver_match_to_hash SEMVER_TAG_REGEX.match(target.name)

    when ::Commit, Gitlab::Git::Commit
      @type = :commit
      @commit = target

    else
      raise ArgumentError.new 'not a valid target'
    end
  end

  def name
    @name || @ref&.name
  end

  def gomod
    @gomod ||= @mod.project.repository.blob_at(@commit.sha, @mod.path + '/go.mod')&.data
  end

  def valid?
    valid_path? && valid_module?
  end

  def valid_path?
    m = VERSION_SUFFIX_REGEX.match(@mod.name)

    case major
    when 0, 1
      m.nil?
    else
      !m.nil? && m[1].to_i == major
    end
  end

  def valid_module?
    return false unless gomod

    gomod.split("\n", 2).first == "module #{@mod.name}"
  end

  def pseudo?
    @type == :pseudo
  end

  def files
    return @files unless @files.nil?

    sha = @commit.sha
    tree = @mod.project.repository.tree(sha, @mod.path, recursive: true).entries.filter { |e| e.file? }
    nested = tree.filter { |e| e.name == 'go.mod' && !(@mod.path == '' && e.path == 'go.mod' || e.path == @mod.path + '/go.mod') }.map { |e| e.path[0..-7] }
    @files = tree.filter { |e| !nested.any? { |n| e.path.start_with? n } }
  end

  def blob_at(path)
    @mod.project.repository.blob_at(@commit.sha, path).data
  end

  private

  def semver_match_to_hash(match)
    return unless match

    OpenStruct.new(
      major: match[1].to_i,
      minor: match[2].to_i,
      patch: match[3].to_i,
      prerelease: match[4],
      build: match[5])
  end
end
