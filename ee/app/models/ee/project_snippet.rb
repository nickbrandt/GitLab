# frozen_string_literal: true

module EE
  module ProjectSnippet
    extend ActiveSupport::Concern

    prepended do
      document_type 'doc'
      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
      include Elastic::SnippetsSearch

      # FIXME: Re-include to avoid a SystemStackError in elasticsearch-model
      # https://github.com/elastic/elasticsearch-rails/issues/144
      include Elasticsearch::Model
    end
  end
end
