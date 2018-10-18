# frozen_string_literal: true

module EE
  module QuickActions
    module InterpretService
      extend ActiveSupport::Concern
      # We use "prepended" here instead of including Gitlab::QuickActions::Dsl,
      # as doing so would clear any existing command definitions.
      prepended do
        # rubocop: disable Cop/InjectEnterpriseEditionModule
        include EE::Gitlab::QuickActions::EpicActions
        include EE::Gitlab::QuickActions::IssueActions
        include EE::Gitlab::QuickActions::MergeRequestActions
        include EE::Gitlab::QuickActions::IssueAndMergeRequestActions
        # rubocop: enable Cop/InjectEnterpriseEditionModule
      end

      desc 'Mark this issue as related to another issue'
      explanation do |related_reference|
        "Marks this issue related to #{related_reference}."
      end
      params '#issue'
      condition do
        issuable.is_a?(Issue) &&
          issuable.persisted? &&
          current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
      end
      command :relate do |related_param|
        @updates[:related_issues] = extract_references(related_param, :issue)
      end
    end
  end
end
