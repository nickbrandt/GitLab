# frozen_string_literal: true

require 'ostruct'
require 'set'

module Tooling
  class TestFileFinder
    EE_PREFIX = 'ee/'

    def initialize(file, foss_test_only: false)
      @file = file
      @foss_test_only = foss_test_only
    end

    def test_files
      matchers = [ee_matcher, foss_matcher]
      matchers.inject(Set.new) do |result, matcher|
        test_files = matcher.match(@file)
        result | test_files
      end.to_a
    end

    private

    attr_reader :file, :foss_test_only, :result

    class TestFileMatcher
      def initialize
        @pattern_matchers = {}

        yield self if block_given?
      end

      def associate(pattern, &block)
        @pattern_matchers[pattern] = block
      end

      def match(file)
        @pattern_matchers.each_with_object(Set.new) do |(pattern, test_matcher), result|
          if (match = pattern.match(file))
            result << test_matcher.call(match)
          end
        end
      end
    end

    def ee_matcher
      TestFileMatcher.new do |matcher|
        unless foss_test_only
          matcher.associate(%r{^#{EE_PREFIX}app/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}_spec.rb" }
          matcher.associate(%r{^#{EE_PREFIX}app/(.*\/)ee/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/#{match[1]}#{match[2]}_spec.rb" }
          matcher.associate(%r{^#{EE_PREFIX}lib/(.+)\.rb$}) { |match| "#{EE_PREFIX}spec/lib/#{match[1]}_spec.rb" }
          matcher.associate(%r{^#{EE_PREFIX}spec/(.+)_spec.rb$}) { |match| match[0] }
        end

        matcher.associate(%r{^#{EE_PREFIX}(?!spec)(.*\/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}_spec.rb" }
        matcher.associate(%r{^#{EE_PREFIX}spec/(.*\/)ee/(.+)\.rb$}) { |match| "spec/#{match[1]}#{match[2]}.rb" }
      end
    end

    def foss_matcher
      TestFileMatcher.new do |matcher|
        matcher.associate(%r{^app/(.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
        matcher.associate(%r{^lib/(.+)\.rb$}) { |match| "spec/lib/#{match[1]}_spec.rb" }
        matcher.associate(%r{^spec/(.+)_spec.rb$}) { |match| match[0] }
        matcher.associate(%r{^(tooling/lib/.+)\.rb$}) { |match| "spec/#{match[1]}_spec.rb" }
      end
    end
  end
end
