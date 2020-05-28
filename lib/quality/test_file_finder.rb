# frozen_string_literal: true

require 'ostruct'

module Quality
  class TestFileFinder
    RUBY_EXTENSION = '.rb'
    EE_PREFIX = 'ee/'

    def initialize(file, foss_test_only: false)
      @file = file
      @foss_test_only = foss_test_only
    end

    def test_files
      contexts = [ee_context, foss_context]
      contexts.flat_map do |context|
        match_test_files_for(context)
      end
    end

    private

    attr_reader :file, :foss_test_only

    def ee_context
      OpenStruct.new.tap do |ee|
        ee.app = %r{^#{EE_PREFIX}app/(.+)\.rb$} unless foss_test_only
        ee.lib = %r{^#{EE_PREFIX}lib/(.+)\.rb$} unless foss_test_only
        ee.spec_dir = "#{EE_PREFIX}spec" unless foss_test_only
        ee.ee_modules = %r{^#{EE_PREFIX}(.*\/)ee/(.+)\.rb$}
        ee.foss_spec_dir = 'spec'
      end
    end

    def foss_context
      OpenStruct.new.tap do |foss|
        foss.app = %r{^app/(.+)\.rb$}
        foss.lib = %r{^lib/(.+)\.rb$}
        foss.spec_dir = 'spec'
      end
    end

    def match_test_files_for(context)
      test_files = []

      if (match = context.app&.match(file))
        test_files << "#{context.spec_dir}/#{match[1]}_spec.rb"
      end

      if (match = context.lib&.match(file))
        test_files << "#{context.spec_dir}/lib/#{match[1]}_spec.rb"
      end

      if (match = context.ee_modules&.match(file))
        test_files << "#{context.foss_spec_dir}/#{match[1]}#{match[2]}_spec.rb"
      end

      test_files
    end
  end
end
