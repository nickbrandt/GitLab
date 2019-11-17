# frozen_string_literal: true

module Issuable
  class BulkUpdateService
    include Gitlab::Allowable

    attr_accessor :parent, :current_user, :params

    def initialize(parent, user = nil, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute(type)
      model_class = type.classify.constantize
      update_class = type.classify.pluralize.constantize::UpdateService

      ids = params.delete(:issuable_ids).split(",")
      items = model_class.where(id: ids)

      permitted_attrs(type).each do |key|
        params.delete(key) unless params[key].present?
      end

      if params[:assignee_ids] == [IssuableFinder::NONE.to_s]
        params[:assignee_ids] = []
      end

      items.each do |issuable|
        next unless can?(current_user, :"update_#{type}", issuable) &&
          valid_parent?(type, issuable.issuing_parent, parent)

        update_class.new(issuable.issuing_parent, current_user, params).execute(issuable)
      end

      {
        count:    items.count,
        success:  !items.count.zero?
      }
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def permitted_attrs(type)
      attrs = %i(state_event milestone_id assignee_id assignee_ids add_label_ids remove_label_ids subscription_event)

      if type == 'issue'
        attrs.push(:assignee_ids)
      else
        attrs.push(:assignee_id)
      end
    end

    def valid_parent?(type, issuing_parent, parent)
      return true unless parent.class.name == 'Group'

      issuing_parents =
        if type == "issue" || type == "merge_request"
          issuing_parent&.group&.self_and_descendants
        else
          issuing_parent&.self_and_descendants
        end

      issuing_parents.include?(parent)
    end
  end
end
