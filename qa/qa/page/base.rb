# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Page
    class Base < Chemlab::Page
      include Support::WaitForRequests
    end
  end
end
