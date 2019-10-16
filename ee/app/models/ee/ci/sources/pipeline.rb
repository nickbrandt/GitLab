# frozen_string_literal: true

module EE
  module Ci
    module Sources
      module Pipeline
        extend ActiveSupport::Concern

        prepended do
          belongs_to :source_bridge,
            class_name: "Ci::Bridge",
            foreign_key: :source_job_id
        end
      end
    end
  end
end
