# frozen_string_literal: true

module EE
  module API
    module ProjectClusters
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :create_params_ee do
            optional :environment_scope, default: '*', type: String, desc: 'The associated environment to the cluster'
          end

          params :update_params_ee do
            optional :environment_scope, type: String, desc: 'The associated environment to the cluster'
          end
        end
      end
    end
  end
end
