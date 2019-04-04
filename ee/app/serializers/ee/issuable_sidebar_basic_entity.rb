# frozen_string_literal: true

module EE
  module IssuableSidebarBasicEntity
    extend ActiveSupport::Concern

    prepended do
      expose :scoped_labels_available do |issuable|
        issuable.project&.feature_available?(:scoped_labels)
      end
    end
  end
end
