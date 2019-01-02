# frozen_string_literal: true

module EE
  module API
    module Issues
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :issues_params_ee do
            optional :weight, types: [Integer, String], integer_none_any: true, desc: 'The weight of the issue'
          end

          params :issue_params_ee do
            optional :weight, type: Integer, desc: 'The weight of the issue'
          end
        end
      end
    end
  end
end
