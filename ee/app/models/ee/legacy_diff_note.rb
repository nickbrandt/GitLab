# frozen_string_literal: true

module EE
  module LegacyDiffNote
    extend ActiveSupport::Concern

    prepended do
      # Elastic search configuration (it does not support STI properly)
      document_type 'doc'
      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
      include Elastic::NotesSearch
    end
  end
end
