# frozen_string_literal: true

module EE
  module HipchatService
    extend ::Gitlab::Utils::Override

    override :create_merge_request_message
    def create_merge_request_message(data)
      data = data.deep_symbolize_keys
      obj_attr = data[:object_attributes]

      # This allows us to correct the `:state` field without having to inject
      # this code in the middle of `create_merge_request_message`.
      obj_attr[:state] = 'approved' if obj_attr[:action] == 'approved'

      super(data)
    end
  end
end
