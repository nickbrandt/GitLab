# frozen_string_literal: true

class Packages::SemVer
  # basic semver, but bounded (^expr$)
  PATTERN = /\A(v?)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?\z/i.freeze

  attr_accessor :major, :minor, :patch, :prerelease, :build

  def initialize(major = 0, minor = 0, patch = 0, prerelease = nil, build = nil, prefixed: false)
    @major = major
    @minor = minor
    @patch = patch
    @prerelease = prerelease
    @build = build
    @prefixed = prefixed
  end

  def prefixed?
    @prefixed
  end

  def ==(other)
    self.class == other.class &&
    self.major == other.major &&
    self.minor == other.minor &&
    self.patch == other.patch &&
    self.prerelease == other.prerelease &&
    self.build == other.build
  end

  def to_s
    s = "#{prefixed? ? 'v' : ''}#{major || 0}.#{minor || 0}.#{patch || 0}"
    s += "-#{prerelease}" if prerelease
    s += "+#{build}" if build

    s
  end

  def self.match(str, prefixed: false)
    m = PATTERN.match(str)
    return unless m
    return if prefixed == m[1].empty?

    m
  end

  def self.match?(str, prefixed: false)
    !match(str, prefixed: prefixed).nil?
  end

  def self.parse(str, prefixed: false)
    m = match str, prefixed: prefixed
    return unless m

    new(m[2].to_i, m[3].to_i, m[4].to_i, m[5], m[6], prefixed: prefixed)
  end
end
