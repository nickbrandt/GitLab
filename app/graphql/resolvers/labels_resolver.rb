# frozen_string_literal: true

module Resolvers
  class LabelsResolver < BaseResolver
    argument  :iid,
              GraphQL::ID_TYPE,
              required: false,
              description: 'The IID of the label, e.g., "1"'
    argument  :iids,
              [GraphQL::ID_TYPE],
              required: false,
              description: 'The list of IIDs of labels, e.g., [1, 2]'
    argument  :title,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The title of the label"
    argument  :description,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The description of the label"
    argument  :color,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The color of the label given in 6-digit hex notation with leading ‘#’ sign (e.g. #FFAABB)"
    argument  :text_color,
              GraphQL::STRING_TYPE,
              required: false,
              description: "The color of the label text given in 6-digit hex notation with leading ‘#’ sign (e.g. #FFFFFF)"

    type Types::LabelType, null: true

    alias_method :issue, :object

    def resolve(**args)
      # The issue could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the issue to query for labels, so
      # make sure it's loaded and not `nil` before continuing.
      issue.sync if issue.respond_to?(:sync)
      return Label.none if issue.nil?

      args[:issue_id] = issue.id
      args[:iids] ||= [args[:iid]].compact

      LabelsFinder.new(context[:current_user], args).execute
    end
  end
end
