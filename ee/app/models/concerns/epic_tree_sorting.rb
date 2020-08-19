# frozen_string_literal: true

module EpicTreeSorting
  extend ActiveSupport::Concern
  include FromUnion
  include RelativePositioning

  class_methods do
    def relative_positioning_query_base(object)
      from_union([
        EpicIssue.select("id, relative_position, epic_id, 'epic_issue' as object_type").in_epic(object.parent_ids),
        Epic.select("id, relative_position, parent_id as epic_id, 'epic' as object_type").where(parent_id: object.parent_ids)
      ])
    end

    def relative_positioning_parent_column
      :epic_id
    end
  end

  included do
    def move_sequence(start_pos, end_pos, delta)
      items_to_update = scoped_items
        .select(:id, :object_type)
        .where('relative_position BETWEEN ? AND ?', start_pos, end_pos)
        .where.not('object_type = ? AND id = ?', self.class.table_name.singularize, self.id)

      items_to_update.group_by { |item| item.object_type }.each do |type, group_items|
        ids = group_items.map(&:id)
        items = type.camelcase.constantize.where(id: ids).select(:id)
        items.update_all("relative_position = relative_position + #{delta}")
      end
    end
  end
end
