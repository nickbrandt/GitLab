# frozen_string_literal: true

module EE
  module Label
    extend ActiveSupport::Concern

    SCOPED_LABEL_PATTERN = /^.*::/.freeze

    def scoped_label?
      SCOPED_LABEL_PATTERN.match?(name) && respond_to?(:subject) && subject.feature_available?(:scoped_labels)
    end

    def scoped_label_key
      title[Label::SCOPED_LABEL_PATTERN]
    end
  end
end
