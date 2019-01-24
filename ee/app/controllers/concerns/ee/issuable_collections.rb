# frozen_string_literal: true

module EE
  module IssuableCollections
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :preload_for_collection
    def preload_for_collection
      @preload_for_collection ||= case collection_type
                                  when 'MergeRequest'
                                    super.push(:approvals)
                                  else
                                    super
                                  end
    end
  end
end
