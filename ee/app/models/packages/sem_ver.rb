# frozen_string_literal: true

module Packages
  class SemVer
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

    def with(**args)
      self.class.new(
        args.fetch(:major, major),
        args.fetch(:minor, minor),
        args.fetch(:patch, patch),
        args.fetch(:prerelease, args.fetch(:pre, prerelease)),
        args.fetch(:build, build),
        prefixed: args.fetch(:prefixed, prefixed?)
      )
    end

    def ==(other)
      self.class == other.class &&
        self.major == other.major &&
        self.minor == other.minor &&
        self.patch == other.patch &&
        self.prerelease == other.prerelease &&
        self.build == other.build
    end

    # rubocop: disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize
    def <=>(other)
      a, b = self, other

      raise ArgumentError.new('Not the same type') unless a.class == b.class

      return 0 if a == b

      return -1 if a.major < b.major
      return +1 if a.major > b.major
      return -1 if a.minor < b.minor
      return +1 if a.minor > b.minor
      return -1 if a.patch < b.patch
      return +1 if a.patch > b.patch

      if a.prerelease == b.prerelease
        # "Build metadata MUST be ignored when determining version precedence."
        # But that would lead to unstable ordering, so check it anyways.
        return 0 if a.build == b.build
        return -1 if !a.build.nil? &&  b.build.nil?
        return +1 if  a.build.nil? && !b.build.nil?
        return -1 if a.build < b.build

        return +1 ## a.build > b.build
      end

      return -1 if !a.prerelease.nil? &&  b.prerelease.nil?
      return +1 if  a.prerelease.nil? && !b.prerelease.nil?

      # "Precedence for [...] patch versions MUST be determined by comparing each
      # dot separated identifier from left to right."
      a_parts = a.prerelease&.split('.') || []
      b_parts = b.prerelease&.split('.') || []

      (0...[a_parts.length, b_parts.length].min).each do |i|
        a_part, b_part = a_parts[i], b_parts[i]
        next if a_part == b_part

        a_num = a_part.to_i if /^\d+$/.match?(a_part)
        b_num = b_part.to_i if /^\d+$/.match?(b_part)

        unless a_num.nil? || b_num.nil?
          return -1 if a_num < b_num
          return +1 if a_num > b_num

          # '0' and '000' have the same precedence, but stable ordering is good.
        end

        # "Numeric identifiers always have lower precedence than non-numeric identifiers."
        return -1 if !a_num.nil? &&  b_num.nil?
        return +1 if  a_num.nil? && !b_num.nil?

        return -1 if a_part < b_part
        return +1 if a_part > b_part
      end

      return -1 if a_parts.length < b_parts.length
      return +1 if a_parts.length > b_parts.length

      return 0
    end
    # rubocop: enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize

    def to_s
      s = "#{prefixed? ? 'v' : ''}#{major || 0}.#{minor || 0}.#{patch || 0}"
      s += "-#{prerelease}" if prerelease
      s += "+#{build}" if build

      s
    end

    def self.match(str, prefixed: false)
      return unless str&.start_with?('v') == prefixed

      str = str[1..] if prefixed

      Gitlab::Regex.semver_regex.match(str)
    end

    def self.match?(str, prefixed: false)
      !match(str, prefixed: prefixed).nil?
    end

    def self.parse(str, prefixed: false)
      m = match str, prefixed: prefixed
      return unless m

      new(m[1].to_i, m[2].to_i, m[3].to_i, m[4], m[5], prefixed: prefixed)
    end
  end
end
