# frozen_string_literal: true

module EE
  module PersonalSnippet
    extend ActiveSupport::Concern

    prepended do
      document_type 'doc'
      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
      include Elastic::SnippetsSearch
    end
  end
end
