# frozen_string_literal: true

module EE
  module MarkdownMatchers
    extend RSpec::Matchers::DSL
    include Capybara::Node::Matchers

    # EpicReferenceFilter
    matcher :reference_epics do
      set_default_markdown_messages

      match do |actual|
        expect(actual).to have_selector('a.gfm.gfm-epic', count: 5)
      end
    end
  end
end
