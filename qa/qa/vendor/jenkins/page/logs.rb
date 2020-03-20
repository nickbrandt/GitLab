# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class Logs < Page::Base
          def path
            "/log/all"
          end

          def build_status_sent_to_gitlab?
            page.has_text?('gitlabjenkins.util.CommitStatusUpdater updateCommitStatus')
          end
        end
      end
    end
  end
end
