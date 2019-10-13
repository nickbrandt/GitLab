# frozen_string_literal: true

FactoryBot.modify do
  factory :protected_branch do
    transient do
      authorize_user_to_push { nil }
      authorize_user_to_merge { nil }
      authorize_user_to_unprotect { nil }
      authorize_group_to_push { nil }
      authorize_group_to_merge { nil }
      authorize_group_to_unprotect { nil }
    end

    after(:build) do |protected_branch, evaluator|
      # Clear access levels set in CE
      protected_branch.push_access_levels.clear
      protected_branch.merge_access_levels.clear

      if user = evaluator.authorize_user_to_push
        protected_branch.push_access_levels.new(user: user)
      end

      if user = evaluator.authorize_user_to_merge
        protected_branch.merge_access_levels.new(user: user)
      end

      if user = evaluator.authorize_user_to_unprotect
        protected_branch.unprotect_access_levels.new(user: user)
      end

      if group = evaluator.authorize_group_to_push
        protected_branch.push_access_levels.new(group: group)
      end

      if group = evaluator.authorize_group_to_merge
        protected_branch.merge_access_levels.new(group: group)
      end

      if group = evaluator.authorize_group_to_unprotect
        protected_branch.unprotect_access_levels.new(group: group)
      end

      next unless protected_branch.merge_access_levels.empty?

      if evaluator.default_access_level && evaluator.default_push_level
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end

      if evaluator.default_access_level && evaluator.default_merge_level
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end
  end
end
