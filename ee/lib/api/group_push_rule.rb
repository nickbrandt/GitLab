# frozen_string_literal: true

module API
  class GroupPushRule < Grape::API::Instance
    before { authenticate! }
    before { authorize_admin_group }
    before { check_feature_availability! }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups do
      helpers do
        def check_feature_availability!
          not_found! unless user_group.feature_available?(:push_rules)
        end
      end

      desc 'Get group push rule' do
        detail 'This feature was introduced in GitLab 13.4.'
        success EE::API::Entities::GroupPushRule
      end
      get ":id/push_rule" do
        push_rule = user_group.push_rule

        not_found! unless push_rule

        present push_rule, with: EE::API::Entities::GroupPushRule, user: current_user
      end
    end
  end
end
