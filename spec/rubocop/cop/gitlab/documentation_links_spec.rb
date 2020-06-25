# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/documentation_links'

RSpec.describe RuboCop::Cop::Gitlab::DocumentationLinks, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'help_page_path' do
    it 'does not add an offense for existing help page path' do
      expect_no_offenses(<<~PATTERN)
      link_to _('More information'), help_page_path('README.md'), target: '_blank'
      PATTERN
    end

    it 'does not add an offense for existing help page path with a valid anchor' do
      expect_no_offenses(<<~PATTERN)
      help_page_path('README.md', anchor: 'overview')
      PATTERN
    end

    it 'adds an offense for existing help page path with invalid anchor' do
      expect_offense(<<~PATTERN)
      help_page_path('README.md', anchor: 'do-not-exist')
      ^^^^^^^^^^^^^^ Invalid anchor
      PATTERN
    end

    it 'adds an offense for missing help page path' do
      expect_offense(<<~PATTERN)
      link_to _('More information'), help_page_path('missing.md'), target: '_blank'
                                     ^^^^^^^^^^^^^^ Documentation link is missing
      PATTERN
    end
  end
end
