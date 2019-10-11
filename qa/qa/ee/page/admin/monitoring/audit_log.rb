# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Monitoring
          class AuditLog < QA::Page::Base
            view 'ee/app/views/admin/audit_logs/index.html.haml' do
              element :admin_audit_log_row_content
            end

            def has_audit_log_row?(text)
              has_element?(:admin_audit_log_row_content, text: text)
            end
          end
        end
      end
    end
  end
end
